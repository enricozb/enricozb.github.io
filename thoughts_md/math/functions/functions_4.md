[title] EZB - Functions

[post_title] Functions 4
[post_subtitle] Look & Say

[prev_post] functions_3.html

[body]

# The Sequence
The [Look & Say sequence](https://en.wikipedia.org/wiki/Look-and-say_sequence)
was originally introduced and analyzed by John Conway. The sequence begins
as follows:

\begin{aligned}
1, 11, 21, 1211, 111221, 312211, \dots
\end{aligned}

To generate a member of the sequence from the previous member, read
the digits of the previous member, counting the number of digits in groups
of the same digit. For example:

1. $1$ is read as "one $1$" or $11$.

2. $11$ is read as "two $1$s" or $21$.

3. $21$ is read as "one $2$, one $1$" or $1211$.

4. $1211$ is read as "one $1$, one $2$, two $1$s” or $111221$.

Notice you can start with a different "seed" or starting number. This
leads to a different sequence. Interestingly enough, $22$ is the only
seed that leads to a sequence that loops. All other seeds generate a
sequence that grows indefinitely.

# The Function Definition
How would you make _this_ into a function using only the constructs we've
introduced? This post will be longer than usuall because of the many parts
required to complete this task. It's not that daunting, but it's going to
take a bit of explaining on my part.

The function we want to create will take in an integer $x$ and output the
next term in the sequence. For example, using the values we computed
in the section above, we would have the following input/output pairs:

\begin{aligned}
  L(1) &= 11 \\
  L(11) &= 21 \\
  L(21) &= 1211 \\
  L(1211) &= 111221 \\
  &\vdots
\end{aligned}

The function could also take any positive integer, and not just those from
the most common sequence. For example,

\begin{aligned}
  L(6) &= 16 \\
  L(73) &= 1713 \\
  L(4444) &= 44 \\
  &\vdots
\end{aligned}

This is the function we want to write out. Let's start off with some
convenience definitions first.

# Grouping
When visually computing the next Look & Say number, we group consecutive
similar digits together. For example, we would group the digits of the
number $11244$ as $[11][2][44]$. Then we use the contents of each group
to generate the next term. This "grouping" action can be done numerically
by computing a number that encodes where these groups start and end. One
way to do this is to create a number that has $1$s on the boundries of
groups and $0$s otherwise. For example, using the number $11244$ again,
we would have

\begin{aligned}
  11244 \to {_11_01_12_14_04_1} \to 101101
\end{aligned}

Notice, this is equivalent to placing $1$s between digits that differ and
$0$s between digits that are the same. Finally pad this number with $1$s
on the left and right side of the entire integer. Here's how we can do this:

\begin{aligned}
  G_{inner}(x) &=
  \sum_{i = 0}^{\text{len}(x) - 2}
    [\text{at}(x, i) \ne \text{at}(x, i + 1)] \cdot 10^i \\
  G(x) &= 1 + 10^{\text{len}(x)} + G_{inner}(x) \cdot 10
\end{aligned}

_Note 1: I've omitted the base $b$ subscript as it's assumed to be $10$._


The keen eye will notice that we haven't defined $\text{neq}$ yet, and
therefore should not be able to use $\neq$, but, it's easily defined
as 

\begin{aligned}
  \text{neq}(x, y) = 1 - \text{eq}(x, y)
\end{aligned}

The way $G$ works is $G_{inner}$ goes through each adjacent pair of digits
in $x$ and "concatenates" a $1$ if they're different and a $0$ otherwise.
Notice this doesn't take into account the $1$s that should be at the
beginning and the end of this grouping number. To take care of this, $G$
shifts $G_{inner}$ over by one digit, and adds a $1$ at the start and end.
These manipulations are easier to think about in terms of string operations,
instead of literally adding numerals.

# Counting Groups
## Intuition
The next big step is to iterate over these groups and build up the next
Look & Say number. A sentence description of what needs to happen would be
something like: For each $1$ in $G(x)$ (from right to left) at index $i$,
let $j$ be the index of the next $1$ in $G(x)$ after the one at index $i$,
then $at(x, i)$ is the digit that occured $j - i$ times in $x$. If we
concatenate these instances of $j - i$ and $at(x, i)$ for each group in
$G(x)$, we'll have the next number.

If we remember from [previous post](functions_3.html), concatenation is hard
because when concatenating $x$ to $y$, we need to know the length of $y$. This
is difficult if you're building up a number via concatenation. In the sorting
case this was easy because each iteration of the loop we would add only one
digit. Here we may add a variable number of digits since $j - i$ could be _any_
value. Thus, we need a function to count the length of the Look & Say number
we have built _so far_, up until group $i$, so that we can concatenate
properly.

Some useful values are: The number of $1$s in $G(x)$ is one greater than the
number of groups of digits in $x$. The number of $0$s in between two $1$s
in $G(x)$ is one less than the number of digits in that group. In a group
bounded by $1$s at indices $i, j$, the length that group contributes to
the next Look & Say number is $\text{len}(j - i) + 1$.

## Formalizing
When iterating through $G(x)$, we only really care about performing operations
where the $1$s are. Thus, we can start off with

\begin{aligned}
  L(x) = \sum_{i = 0}^{\text{len}(G(x)) - 2} at(G(x), i) \cdot [\dots]
\end{aligned}

_Note_: The last index is subtracted by $2$ because the last $1$ is not the
start boundary of a group, but instead and an end.

where $[\dots]$ represents stuff we still need to write. The
$\text{at}(G(x), i)$ serves as discarding the computations in $[\dots]$ when
the digit at index $i$ is $0$.

Now, as we said in the previous section, we need to find the index of the next
$1$, and then concatenate that and the corresponding digit in $x$ to our
ongoing computation. If $G_{len}(x, i)$ is the length of the group at index $i$
and $\sigma(x, i)$ is new index of the group length & digit pair, then we have

\begin{aligned}
  \sigma(x, i) &= [\dots] \\
  G_{len}(x, i) &= [\dots] \\
  L_{pair}(x, i) &= G_{len}(x, i) \cdot 10 + \text{at}(x, i) \\
  L(x) &= \sum_{i = 0}^{\text{len}(G(x)) - 1} \text{at}(G(x), i) \cdot
    L_{pair}(x, i) \cdot 10^{\sigma(x, i)}
\end{aligned}

## Tackling $\sigma$
I think $\sigma(x, i)$ is pretty easy assuming we already have $G_{len}$. It's
essentially the number of digits that have been concatenated already. Thus, the
sum of all of the _lengths_ of $G_{len}$s and groups less than $i$. This is
because having a group of length $10$ adds $3$ new digits, to $L(x)$: the group
length ($10$), and the corresponding group digit. Thus, this can be written as

\begin{aligned}
  \sigma(x, i) = \sum_{j = 0}^{i - 1} at(G(x), j) \cdot
    (\text{len}(G_{len}(x, j)) + 1)
\end{aligned}

_Note_: again, we don't care about indices where $G(x)$ is $0$.

## Tackling $G_{len}$
$G_{len}(x, i)$ is simply the length of the group at index $i$ in $x$. So we
know the first $1$ is at index $i$. Then we need to find the index of the next
$1$. Here's an example $G(x)$ with $i, j$ indicated when $i = 2$:

\begin{aligned}
  G(22344455) &\to {_12_02_13_14_04_04_15_05_1} \to 101100101 \\
  G(x) &= 101\underset{j}{1}00\underset{i}{1}01 \\
\end{aligned}

The number we care about is $j - i$, since that is equal to the length of the
group. We would expect, in this case, that $G_{len}(22344455, 2) = 3$, since
the group of $4$s is of length $3$. One way to compute $j - i$ is to truncate
the digits at indices before and including $i$ in $G(x)$, then take the length
of the reverse of the resulting number and subtract it from the length of the
truncation before the reversal and add $1$. Here's a diagram that's hopefully
more understandable:

\begin{aligned}
  [10&1\underset{j}{1}00]\underset{i}{1}01 \\
  &\downarrow \text{truncate} \\
  a = 10&1100 \\
  &\downarrow \text{reverse} \\
  b = 11&01 \\
  &\downarrow \text{compute} \\
  \text{len}(a) &- \text{len}(b) = 2
\end{aligned}

We would write that like this:

\begin{aligned}
  G_{tr}(x, i) &= \left\lfloor \frac{G(x)}{10^{i + 1}} \right\rfloor \\
  G_{len}(x, i) &= 1 + \text{len}(G_{tr}(x, i)) -
                \text{len}(\text{rev}(G_{tr}(x, i)))
\end{aligned}

## Recap
Let's just rewrite all of the functions here for convenience

\begin{aligned}
  G_{inner}(x) &= \sum_{i = 0}^{\text{len}(x) - 2}
    [\text{at}(x, i) \ne \text{at}(x, i + 1)] \cdot 10^i \\
  G(x) &= 1 + 10^{\text{len}(x)} + G_{inner}(x) \cdot 10 \\
  \sigma(x, i) &= \sum_{j = 0}^{i - 1} at(G(x), j) \cdot (G_{len}(x, j) + 1) \\
  G_{tr}(x, i) &= \left\lfloor \frac{G(x)}{10^{i + 1}} \right\rfloor \\
  G_{len}(x, i) &= 1 + \text{len}(G_{tr}(x, i)) -
                \text{len}(\text{rev}(G_{tr}(x, i))) \\
  L_{pair}(x, i) &= G_{len}(x, i) \cdot 10 + \text{at}(x, i) \\
  L(x) &= \sum_{i = 0}^{\text{len}(G(x)) - 1} \text{at}(G(x), i) \cdot
    L_{pair}(x, i) \cdot 10^{\sigma(x, i)}
\end{aligned}

# Codified Functions

Let's keep with the tradition of writing everything out as python functions.

```python
from math import *

def len(x, b):
  return ceil(log(x + 1, b))

def at(x, i, b):
  return floor(abs(x) / (b ** i)) % b

def rev(x, b):
  return sum(at(x, i, b) * (b ** (len(x, b) - i - 1))
    for i in range(len(x, b)))

def sign(x):
    return floor(x / (abs(x) + 1)) + ceil(x / (abs(x) + 1))

def neq(x, y):
    return ceil(abs(x - y) / (abs(x - y) + 1))

def G_inner(x):
    return sum(neq(at(x, i, 10), at(x, i + 1, 10)) * 10 ** i
        for i in range(len(x, 10) - 1))

def G(x):
    return 1 + 10 ** len(x, 10) + G_inner(x) * 10

def sigma(x, i):
    return sum(at(G(x), j, 10) * (len(G_len(x, j), 10) + 1)
        for j in range(i))

def G_tr(x, i):
    return floor(G(x) / 10 ** (i + 1))

def G_len(x, i):
    return 1 + len(G_tr(x, i), 10) - len(rev(G_tr(x, i), 10), 10)

def L_pair(x, i):
    return G_len(x, i) * 10 + at(x, i, 10)

def L(x):
    return sum(at(G(x), i, 10) * L_pair(x, i) * 10 ** sigma(x, i)
        for i in range(len(G(x), 10) - 1))
```

Does it work?

```python
`Keyword.Import]>>>` L(1)
11
`Keyword.Import]>>>` L(11)
21
`Keyword.Import]>>>` L(21)
1211
`Keyword.Import]>>>` L(1211)
111221
`Keyword.Import]>>>` L(111221)
312211
```

Heck yea it works! Isn't that crazy? What's even cooler is looking at some $x$
values that we don't usually consider, and see if we can find meaning in those.

```python
`Keyword.Import]>>>` L(0)
0
```

Hmmm... Well, I guess that makes sense right? We could interpret this as there
being no $0$s, hence we'd expect $L(0) = 00 = 0$. Fair enough.

```python
`Keyword.Import]>>>` L(0)
ValueError: math domain error
```
Ah, this is because $\text{len}$ relies on $\log$, whose domain is only the
non-negative reals. No real way around that I think.

# Conclusion
This was a pretty fun "adventure" to go on as a high schooler. I previously saw
the Look & Say numberphile video and was so intrigued by the sequence. When I
came up with this I thought I could be on the show, but of course I was (and
still am) just a kid. It took me about 2-3 weeks to come up with this and make
sure it actually worked.

I'm not sure how much further we can go with this. I was thinking if it's possible
to make a function $L_i(s, i)$ that can take a seed $s$ and an index $i$ without
using the super-function notation. That is, this could be written as

\begin{aligned}
  L_i(s, i) = L^{(i)}(s)
\end{aligned}

but I was wondering if there was a way to do this without introducing any new
notation. I haven't come up with anything yet though.

On the next (and likely last) functions post, we'll talk about stuff I haven't
figured out and maybe gloss over the other interesting functions I haven't yet
mentioned.

