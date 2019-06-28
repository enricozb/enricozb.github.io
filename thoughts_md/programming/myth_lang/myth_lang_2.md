[title] EZB - MythLang

[post_title] MythLang 2
[post_subtitle] Lexing & Parsing

[prev_post] ezb.io/thoughts
[next_post] myth_lang_3.html

[body]
# Disclaimer
Myth's lexer is built with
[ocamllex](https://caml.inria.fr/pub/docs/manual-ocaml/lexyacc.html), since
that was the first meaningful result that came up when I searched "lexing with
OCaml". It's nice enough to use. Either way, the code I've written is pure
garbage. The way newlines, `INDENT`s, and `DEDENT`s are handled is annoying,
and the parser & lexer are way to tightly coupled. But, it's the code that's
currently running so, whatever.

# A Whitespace-Sensitive Lexer
Myth's syntax is heavily inspired by Python. I wanted something that was
whitespace-sensitive and used indentation to specify code blocks. So I decided
to look at the [Python 3.7
Grammar](https://docs.python.org/3/reference/grammar.html) to see how they
handled whitespace-sensitivity. I saw that a lot of the rules depended on
`INDENT` and `DEDENT` tokens. So I'd have to make my lexer figure out when to
emit those. However, it's often the case that after reading a single `\n`
character followed by a non-whitespace character, we will want to emit multiple
`DEDENT` tokens. For example,
```python
if True:
  if True:
    if True:
      pass
print()
```
when the lexer sees the `\n` followed by the `p` in `print`, three `DEDENT`
tokens need to be emitted, one for each `if` block. So I had to find a way
to handle this multiple `DEDENT` nonsense.

## The Lexer Code
This isn't really the place for an ocamllex tutorial, so we'll just look at the
code immediately. The meat of the lexer (ignoring the non-interesting rules)
looks something like

```ocaml
rule token = parse
  | ['\n'] {
    if !paren_count = 0 then begin
      state := RECENT_NEWLINE;
      NEWLINE
    end else
      token lexbuf
  }
  | ['('] {
    incr paren_count;
    LPAREN
  }
  | [')'] {
    decr paren_count;
    RPAREN
  }
  | ['a'-'z' '_']+ ['a'-'z' 'A'-'Z' '0'-'9' '_']* as id {
    check_keyword id
  }
  (*... other rules ... *)
```
Some important points to notice:

  1. We have some special logic in when handling `\n`.
  2. We track parenthesis usage, in order to ignore indents within
     parenthesized pieces of code across multiple lines.
  3. Keywords are checked in a function, not in the lexer rules.

We have a special `state` variable that has the following type and initial
value:
```ocaml
type state =
  | CODE
  | RECENT_NEWLINE

let state = ref CODE
```
We'll see why these is useful soon. We also have a variable `paren_count`
that is initialized to `ref 0`. This just keeps track of whether or not we
are inside a parenthesized expression. If we are, then indents and newlines
are ignored. Lastly, keywords are checked in a special function
`check_keyword`, this is because, as per [ocamllex
documentation](https://caml.inria.fr/pub/docs/manual-ocaml/lexyacc.html#sec333),
this should be done to keep the generated transition table small. The
definition is something like
```ocaml
let check_keyword = function
  | "if" -> IF
  | "else" -> ELSE
  | "while" -> WHILE
  | "def" -> DEF
  | "return" -> RETURN
  | "and" -> OPERATOR "and"
  | "or" -> OPERATOR "or"
  | id -> NAME id
```
In addition to the rule `token`, we also have the rule `newline`, which is
defined as follows:

```ocaml
and newline = parse
  | [' ']* as spaces {
    state := CODE;
    match count_indent (String.length spaces) with
    | `Skip -> token lexbuf
    | `Token t -> t
  }
```

This counts the spaces immediately after a newline, in order to determine
what indent block we are currently on. Specifically, we want to determine
if we should emit an `INDENT` token, or several `DEDENT` tokens followed
by a newline. Here's the definition of `count_indent`

```ocaml
let space_stack = Stack.create ()
let _ = Stack.push 0 space_stack

(* outputs INDENT, DEDENT, or DEDENTMANY tokens *)
let count_indent count =
  if Stack.top space_stack = count then
    `Skip
  else if Stack.top space_stack < count then begin
    Stack.push count space_stack;
    `Token INDENT
  end else
    (* Pop from the stack until we get an equal indent *)
    let dedent_count = ref 0 in
    try
      while true do
        if Stack.top space_stack = count then
          raise Exit
        else
          incr dedent_count;
          ignore (Stack.pop space_stack);
      done;
      raise SyntaxError
    with Exit -> `Token (DEDENTMANY !dedent_count)
```
This is some awful code... What it essentially does is, we have a stack of
integers, `space_stack`, that keeps the counts for the number of spaces used
to indent blocks. For example, if the lexer is given this piece of code:
```python
if True:
  if True:
      if True:
       if True:
        pass
```
when it reaches `pass`, the space stack will have the contents `[0, 2, 6, 7,
8]`.  These numbers are the number of spaces used in each indent block. So,
when we dedent, we need to return to a preexisting number of spaces. The space
stack ensures that we do this. Furthermore, when deindenting, `count_indent`
counts how many `DEDENTS` needs to be output, and reports this using a
`DEDENTMANY` token, which contains an `int` (the number of `DEDENT`s to
output).

Finally, the last part of the lexer is the part that handles outputting
multiple `DEDENT` tokens. It works like this: inside the lexer, there is
a function called `token_cache` that has the following definition:
```ocaml
let token_cache =
  let cache = ref [] in
  fun lexbuf ->
    match !cache with
    | x::xs -> cache := xs; x
    | [] ->
        match !Lexer.state with
        | Lexer.CODE -> Lexer.token lexbuf
        | Lexer.RECENT_NEWLINE -> begin
            match Lexer.newline lexbuf with
            | DEDENTMANY n -> begin
                cache := (replicate (n - 1) DEDENT);
                DEDENT
            end
            | token -> token
        end
```

It essentially keeps a reference to a list (`cache`) that gets filled
with `DEDENT` tokens once a `DEDENTMANY` token is output by the lexer. Notice
that the parser never expects a `DEDENTMANY` token, that is only used
internally by the lexer.

## Using The Lexer
When looking at ocamllex tutorials, you'll usually see the main lexing rule
defined as `token`. Then, in the main program, or wherever the lexer needs
to be used, you'll see a call to `Lexer.token`. In order to use this
whitespace sensitive lexer, you'll instead use `Lexer.token_cache`, as your
"rule" instead of `token`.

# The Parser (parser.mly)
I'm using [Menhir](http://gallium.inria.fr/~fpottier/menhir/) for parsing,
since it supports incremental parsing reasonably nicely. This is so I can
parse multiline code inside a REPL, which will hopefully be touched on
in a later blog post. The parser isn't anything too fancy. The most interesting
thing is how operator precedence is handled, which I'll detail here. If
you're only interested in the whitespace-sensitivity bit, skip this part I
guess.

Somewhere deep in my parser, I have the following bit of
[BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form) grammar:

```ocaml
expr:
  | non_op_expr                  { $1 }
  | non_op_expr op_list          { resolve_op_list $1 $2 }

op_list:
  | OPERATOR non_op_expr         { [($1, $2)] }
  | OPERATOR non_op_expr op_list { ($1, $2) :: $3 }
```
Basically, it's meant to match expressions of the following nature
```python
1 + 2 ^ 3 * 4
```
And the `resolve_op_list` call on this expression would look something like
```ocaml
resolve_op_list
  (Ast.Num 1)
  [("+", Ast.Num 2), ("^", Ast.Num 3), ("*", Ast.Num 4)]
```
The `Ast.Num` stuff is just how my language internally represents its [abstract
syntax tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree).

The `resolve_op_list` code is a bit too long to post here I think, so check
it out [on the
repo](https://github.com/enricozb/CS81-2019/blob/master/src/custom/repl/parser.mly#L31-L97)
The way it works isn't too complicated though. I defined some precedences
for each operator. It's a function that takes in an operator and outputs
and associativity
```ocaml
let assoc_f i (_, op) = match op with
  | "or" -> (0, -i)
  | "and" -> (1, -i)
  | "<" | "<=" | ">" | ">=" | "!=" | "==" -> (2, -i)
  | "+" | "-" -> (3, -i)
  | "*" | "/" -> (4, -i)
  | "^" -> (5, i)
  | _ -> failwith "Unknown operator."
```
You'll notice it also takes in an integer `i`. This is the index of the
operator in a list of operators. The index is passed in so we can also take
into account
[associativity](https://en.wikipedia.org/wiki/Operator_associativity). Namely,
if I search for the minimum precedence element in a list, I will find the
left-most, or the right-most operator of minimum precedence, depending on
the associativity.

The rest of the `resolve_op_list` just finds the minimum precedence operator
and splits the lists of operators and expressions at that minimum precedence
operator. Then it recurses on those two smaller left and right lists.

The ability to handle operators like this is super useful for two reasons:
  1. Custom operators are easily added by the user.
  2. I don't need to write BNF rules for specific operators.


# Conclusion
My code is garbage. That's the end of the lexing/parsing bit. The rest of the
lexer and parser is just standard stuff that is specific to Myth, and not
that generalizable. The next post will probably be on the type system, or
my serious issues with mutability, or Hindley-Milner, or idk.
