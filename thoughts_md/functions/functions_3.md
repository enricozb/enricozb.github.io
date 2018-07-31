[title] EZB - functions

[thoughts_file] ../../thoughts.html
[css_file] ../../css/main.css

[post_title] Functions 3
[prev_post] functions_2.html

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

$$ \begin{aligned}
\text{lt}(x, y) &= \text{eq}(-1, \text{sign}(x - y)) \\
\text{gt}(x, y) &= \text{eq}(1, \text{sign}(x - y)) \\
\text{leq}(x, y) &= 1 - \text{gt}(x, y) \\
\text{geq}(x, y) &= 1 - \text{lt}(x, y)
\end{aligned} $$

where the equations are `x < y`, `x > y`, `x <= y`, and `x >= y`>, respectively.
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
$$ \text{sort}(31524) = 54321 $$
The reason we sort in "decreasing" order is twofold:
Since the digit at index $i = 0$ is the rightmost digit, sorting in this
direction would mean that iterating from $i = 0$ to
$\text{len}(x, b) - 1$ would traverse the digits in increasing order.
Furthermore, we sort in this order to preserve $0$'s. If we
sorted in the other direction, $1001$ and $101$ would look the same when
sorted, which is not a desirable quality.

# Implementation
Sorting follows pretty naturally after reversing. Reversing is simply
taking every digit of a number and placing it at a new index. Sorting
is the exact same thing, except that function that decides the new
indices is different. That is,
$$ \text{sort}(x, b) =
\sum_{i = 0}^{\text{len}(x, b) - 1} \text{at}(x, b, i) \cdot
  10^{\sigma(x, b, i)} $$
where $\sigma(x, b, i)$ returns the index of the digit $i$ of $x$
in base $b$ when sorted. Notice this is exactly $\text{rev}$ when

$$\sigma_{rev}(x, b, i) = \text{len}(x, b) - i - 1$$

Now, what would $\sigma_{sort}(x, b, i)$ be? A reasonable guess for
would be the number of digits in $x$ less than $\text{at}(x, b, i)$.
That is,

$$\sigma_{sort}(x, b, i) = \sum_{j = 0}^{\text{len}(x, b) - 1}
[\text{at}(x, b, j) < \text{at}(x, b, i)] $$

This doesn't work for numbers with duplicate digits, however, as this
would send both instances of the digit $3$ in the number
$1233$ to the same index.


What we ended up coming up with was this: $\sigma_{sort}$ would be the
number of digits in $x$ strictly less than $\text{at}(x, b, i)$
*plus* the number of instances of the digit $\text{at}(x, b, i)$ at
indices less than $i$. That is,

\begin{aligned}
  \sigma_{eq}(x, b, i) &= \sum_{j = 0}^{i - 1}
    [\text{at}(x, b, j) = \text{at}(x, b, i)] \\

  \sigma_{lt}(x, b, i) &= \sum_{j = 0}^{\text{len}(x, b) - 1}
  [\text{at}(x, b, j) < \text{at}(x, b, i)] \\

  \sigma_{sort}(x, b, i) &= \sigma_{eq}(x, b, i) + \sigma_{lt}(x, b, i)

\end{aligned}

Now we can define $\text{sort}$ as,
$$ \text{sort}(x, b) =
\sum_{i = 0}^{\text{len}(x, b) - 1} \text{at}(x, b, i) \cdot
  10^{\sigma(x, b, i)} $$

Similar to what we did in [Functions 2](functions2.html)
we can convert this definition to code. Here's an example in Python,

```python
from math import *

def sign(x):
    return floor(x / (abs(x) + 1)) + ceil(x / (abs(x) + 1))

def eq(x, y):
    return 1 - ceil(abs(x - y) / (abs(x - y) + 1))

def lt(x, y):
    return eq(-1, sign(x - y))

def sigma_eq(x, b, i):
    return sum(eq(at(x, b, j), at(x, b, i)) for j in range(0, i))

def sigma_lt(x, b, i):
    return sum(lt(at(x, b, j), at(x, b, i)) for j in range(0, len(x, b)))

def sigma_sort(x, b, i):
    return sigma_eq(x, b, i) + sigma_lt(x, b, i)

def sort(x, b):
    return sum(at(x, b, i) * 10 ** sigma_sort(x, b, i)
            for i in range(len(x, b)))
```
