[title] EZB - Functions

[post_title] Functions 3
[post_subtitle] Sorting an Integer

[prev_post] functions_2.html
[next_post] functions_4.html

[body]

# Relations & Notation
Before getting too deep into how sorting works, I'm going to introduce
some new functions and convenience notation first. In the
[first post](functions_1.html) in this series, we talked
about $\text{eq}$, which is a relation. A relation can be defined for
our needs as a function of two arguments that always evaluates to either
$0$ or $1$. That is, it is a function $f$ with the type signature

$$ f : \mathbb{R} \to \{0, 1\} $$

Other common relations can be defined as follows:

\begin{aligned}
    \text{lt}(x, y) &= \text{eq}(-1, \text{sign}(x - y)) \\
    \text{gt}(x, y) &= \text{eq}(1, \text{sign}(x - y)) \\
    \text{leq}(x, y) &= 1 - \text{gt}(x, y) \\
    \text{geq}(x, y) &= 1 - \text{lt}(x, y)
\end{aligned}

where the equations are `x < y`, `x > y`, `x <= y`, and `x >= y`, respectively.
"Calling" these relations each time get cumbersome, so we will be using a
notation inspired by the
[Iverson Bracket](https://en.wikipedia.org/wiki/Iverson_bracket)
for convenience. Instead of writing $\text{lt}(x, y)$, we will
write $[x < y]$. This extends to the other relations defined above.


*Note:* We will only use
it with comparison operators whose functions have been previously
defined, so that we are always using only binary & elementary operations
"under the hood".

# Sorting
## What do we mean by sorting?
Since the primary "data" that we are working with are
integers, a sorting function would be one that sorts the digits within
an integer. For example,
$$ \text{sort}_{10}(31524_{10}) = 54321_{10} $$
The reason we sort in "decreasing" order is twofold:
Since the digit at index $i = 0$ is the rightmost digit, sorting in this
direction would mean that iterating from $i = 0$ to
$\text{len}_b(x) - 1$ would traverse the digits in increasing order.
Furthermore, we sort in this order to preserve $0$'s. If we
sorted in the other direction, $1001$ and $101$ would look the same when
sorted in base $10$, which is not a desirable quality.

# Implementation
Sorting follows pretty naturally after reversing. Reversing is simply
taking every digit of a number and placing it at a new index. Sorting
is the exact same thing, except that the function that decides the new
indices is different. That is,

\begin{aligned}
  \text{sort}_b(x) =
  \sum_{i = 0}^{\text{len}_b(x) - 1} \text{at}_b(x, i) \cdot
    b^{\sigma(x, i, b)}
\end{aligned}

where $\sigma(x, i, b)$ returns the new index of the digit at index $i$ of
$x$ in base $b$. Notice this is exactly $\text{rev}$ when

$$\sigma_{rev}(x, i, b) = \text{len}_b(x) - i - 1$$

Now, what would $\sigma_{sort}(x, i, b)$ be? A reasonable guess for
would be the number of digits in $x$ less than $\text{at}(x, i, b)$.
That is,

\begin{aligned}
  \sigma_{sort}(x, i, b) = \sum_{j = 0}^{\text{len}_b(x) - 1}
    [\text{at}_b(x, j) < \text{at}_b(x, i)]
\end{aligned}

This doesn't work for numbers with duplicate digits, however, as this
would send both instances of the digit $3$ in the number
$1233$ to the same index.


What we ended up coming up with was this: $\sigma_{sort}$ would be the
number of digits in $x$ strictly less than $\text{at}_b(x, i)$
*plus* the number of instances of the digit $\text{at}_b(x, i)$ at
indices less than $i$. That is,

\begin{aligned}
  \sigma_{eq}(x, i, b) &= \sum_{j = 0}^{i - 1}
    [\text{at}_b(x, j) = \text{at}_b(x, i)] \\

  \sigma_{lt}(x, i, b) &= \sum_{j = 0}^{\text{len}_b(x) - 1}
  [\text{at}_b(x, j) < \text{at}_b(x, i)] \\

  \sigma_{sort}(x, i, b) &= \sigma_{eq}(x, i, b) + \sigma_{lt}(x, i, b)
\end{aligned}

Now we can define $\text{sort}$ as,

\begin{aligned}
  \text{sort}_b(x) =
    \sum_{i = 0}^{\text{len}_b(x) - 1} \text{at}_b(x, i) \cdot
      b^{{\sigma_{sort}}(x, i, b)}
\end{aligned}

An interesting side note here is that, in some sense, this sort is
[stable](https://stackoverflow.com/questions/1517793/what-is-stability-in-sorting-algorithms-and-why-is-it-important).
Obviously integers don't really have any sense of identity. Every $1$
is the same as every other $1$ in the pool of integers $\mathbb{Z}$.
If digits did have some sort of identity, as they do in computers,
then this sorting function would be considered stable.

Similar to what we did in [Functions 2](functions_2.html)
we can convert this definition to code. Here's an example in Python,

```python
from math import *

def len(x, b):
  return ceil(log(x + 1, b))

def at(x, i, b):
  return floor(abs(x) / (b ** i)) % b

def sign(x):
  return floor(x / (abs(x) + 1)) + ceil(x / (abs(x) + 1))

def eq(x, y):
  return 1 - ceil(abs(x - y) / (abs(x - y) + 1))

def lt(x, y):
  return eq(-1, sign(x - y))

def sigma_eq(x, i, b):
  return sum(eq(at(x, j, b), at(x, i, b)) for j in range(0, i))

def sigma_lt(x, i, b):
  return sum(lt(at(x, j, b), at(x, i, b)) for j in range(0, len(x, b)))

def sigma_sort(x, i, b):
  return sigma_eq(x, i, b) + sigma_lt(x, i, b)

def sort(x, b):
  return sum(at(x, i, b) * b ** sigma_sort(x, i, b)
    for i in range(len(x, b)))
```

And again let's test it out to see if it works:

```python
`Keyword.Import]>>>` sort(18081971, 10)
98871110
`Keyword.Import]>>>` sort(0o1420740, 8) == 0o7442100
True
`Keyword.Import]>>>` sort(0xcafebabe, 16) == 0xfeecbbaa
True
```

Sweet! Looks like we can sort integers now. Next we'll probably talk
about making a Look and Say function $L(x)$, that takes in an integer
$x$ and outputs the next term in the
[Look and Say sequence](https://en.wikipedia.org/wiki/Look-and-say_sequence).

