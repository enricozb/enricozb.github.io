[title] EZB - Functions

[post_title] Functions 2
[prev_post] functions_1.html
[next_post] functions_3.html

[body]

Before showing you the function that we came up with to reverse a number,
we have to define two functions. First, $\text{len}(x, b)$, which gives
the number of digits in $x$ when written in base $b$.

$$ \text{len}(x, b) = \big\lceil \log_b(x + 1) \big\rceil $$

Then, we have $\text{at}(x, b, i)$, which gives the digit at index $i$
of $x$ when written in base $b$. This is zero-indexed and $i=0$ refers
to the least significant digit. For example $\text{at}(123, 10, 0) = 3$

$$ \text{at}(x, b, i) =
\left\lfloor \frac{\lvert x \rvert}{b^i} \right\rfloor
\text{ mod } b $$

Here, $\text{mod}$ is an operator, not the equivalence class. Now,
here's our definition of reverse,

$$ \text{rev}(x, b) =
\sum_{i = 0}^{\text{len}(x, b) - 1} \text{at}(x, b, i) \cdot
  10^{\text{len}(x, b) - i - 1} $$

Let's break this down. The $\Sigma$ can be described as a
"loop". We loop through all of the valid indices $i$ of the
digits in $x$. For each index $i$, we take the digit in $x$ at that
index and "place" it in a new number at a new index
$\text{len}(x, b) - i - 1$. Notice, this new index is exactly the index
of this digit in the reversed number.


What's even cooler is that we can translate our definition of
$\text{rev}$ *back into code*. Here's a snippet using Python,


```python
from math import *

def len(x, b):
  return ceil(log(x + 1, b))

def at(x, b, i):
  return floor(abs(x) / (b ** i)) % b

def rev(x, b):
  return sum(at(x, b, i) * (10 ** (len(x, b) - i - 1))
    for i in range(len(x, b) - 1))
```


Even though this is over 10x slower than the naive string-reversal
approach, it's still pretty cool that this can be done using only binary
operations.


Next, we'll talk about sorting the digits of an integer.