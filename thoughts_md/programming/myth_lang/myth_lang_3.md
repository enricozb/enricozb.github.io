[title] EZB - MythLang

[post_title] MythLang 3
[post_subtitle] Mutability

[prev_post] myth_lang_2.html

[body]
# Hindley-Milner and Mutability
After implementing Hindley-Milner, I had type inference. It was good enough
to start with, and I thought the next big stepping stone was mutability.
Specifically, I wanted mutable bindings, but not necessarily mutable objects.
Basically, I wanted something like this to work
```python
def f(v):
  x = 0
  if v > 0:
    x = 1
  else:
    x = -1
  return x
```
Obviously this can be written in a way without mutable bindings, but
mutable bindings are often useful for global counters and other imperative
structures. I also wanted to distinguish between assignments, bindings, and
mutable bindings. So the syntax now looks like
```python
def f(v):
  let y = 0
  let mut x = 0
  if v > 0:
    x = 1
  else:
    x = -1
  return [x, y]
```

## Value Restriction
So, for inspiration, I decided to look at how OCaml implements it's mutable
references, which is different than what I wanted, but is close enough.
Specifically, OCaml has a `ref` function, which creates a mutable reference
which can be _passed around_. What I wanted is not a reference that could
be passed around, but bindings that could be rebound during the execution of
the program. Either way, let's take a look at OCaml's type inference with calls
to `ref`:
```ocaml
>>> let x = ref [];;
    x : '_weak1 list ref = {contents = []}
```
So we see here that `x` has the type `Ref[List[_weak1]]`. Basically, the type
variable `_weak1` is a variable that can't be generalized. So when
instantiating it, we get the same `_weak1` variable back. What OCaml implements
is what is known as _the value restriction_. It's basically a modification of
Hindley-Milner's `generalize` function. It generalizes only specific
syntactical structures. Namely, it generalizes only the structures that are
sure to not create a mutable reference. So what used to be simple calls to
`generalize` are now replaced with
```ocaml
if mut || is_expansive ast then
  ty
else
  generalize level ty
```
where `mut` just tells us if the binding is mutable. At the very bottom of
[this page](https://caml.inria.fr/pub/docs/oreilly-book/html/book-ora026.html)
we can see a list of expressions considered expansive and non-expansive. This
is what is computed by `is_expansive` in the code above. It just checks if
an expression could potentially create a mutable binding:
```ocaml
let is_expansive = function
  | Ast.Name _
  | Ast.Num _
  | Ast.List _   (* TODO: change if List becomes mutable *)
  | Ast.Lambda _
  | Ast.Field _  (* TODO: change if mutable fields are added *)
  | Ast.Record _ (* TODO: change if mutable fields are added *)
    -> false

  | Ast.Call _ -> true
  | _ -> failwith "Type.is_expansive called on non-expression"
```
As we can see, this has to be changed as changes are made to the language. For
example, if I make the list object, `[]`, mutable, then we need to never
generalize any use of the list constructor.

## Relaxation
The value restriction is a bit pessimistic, specifically when returning
polymorphic values from function calls. This can be resolved in most cases
with a deceptively simple change to generalization described in
[this paper](https://caml.inria.fr/pub/papers/garrigue-value_restriction-fiwflp04.pdf).
I have yet to implement this, but hopefully will soon.

I'll probably talk about recursive types next. I've added extensible records
already at the time of this writing, but they're not as useful as I'd like
them to be. Their use will dramatically increase with recursive typing,
since I can have concepts such as `self`.

