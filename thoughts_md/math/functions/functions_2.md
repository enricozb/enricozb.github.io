[title] EZB - Functions

[post_title] Functions 2
[prev_post] functions_1.html
[next_post] functions_3.html

[body]

Before showing you the function that we came up with to reverse a number,
we have to define two functions. First, $\text{len}_b(x)$, which gives
the number of digits in $x$ when written in base $b$.

$$ \text{len}_b(x) = \big\lceil \log_b(x + 1) \big\rceil $$

Then, we have $\text{at}_b(x, i)$, which gives the digit at index $i$
of $x$ when written in base $b$. This is zero-indexed and $i=0$ refers
to the least significant digit. For example $\text{at}_{10}(123, 0) = 3$

$$ \text{at}_b(x, i) =
\left\lfloor \frac{\lvert x \rvert}{b^i} \right\rfloor
\text{ mod } b $$

Here, $\text{mod}$ is an operator, not the equivalence class. Now,
here's our definition of reverse,

$$ \text{rev}_b(x) =
\sum_{i = 0}^{\text{len}_b(x) - 1} \text{at}_b(x, i) \cdot
  b^{\text{len}_b(x) - i - 1} $$

Let's break this down. The $\Sigma$ can be described as a
"loop". We loop through all of the valid indices $i$ of the
digits in $x$. For each index $i$, we take the digit in $x$ at that
index and "place" it in a new number at a new index
$\text{len}_b(x) - i - 1$. Notice, this new index is exactly the index
of this digit in the reversed number.


What's even cooler is that we can translate our definition of
$\text{rev}$ *back into code*. Here's a snippet using Python,


```python
from math import *

def len(x, b):
  return ceil(log(x + 1, b))

def at(x, i, b):
  return floor(abs(x) / (b ** i)) % b

def rev(x, b):
  return sum(at(x, i, b) * (b ** (len(x, b) - i - 1))
    for i in range(len(x, b)))
```

Let's test it out here to verify that it it works:


```python
`Keyword.Import]>>>` rev(12345, 10)
54321
`Keyword.Import]>>>` f"{12345:o}"
'30071'
`Keyword.Import]>>>` f"{rev(12345, 8):o}"
'17003'
```

Awesome! The first expression shows that $12345$ reversed when written in
base $10$ comes out to $54321$, which is what we expected! Then we see that
$12345_{10} = 30071_8$. Therefore, reversing with respect to base $8$ comes
out to the correct value, $17003_8$.

Even though this is over 10x slower than the naive string-reversal
approach, it's still pretty cool that this can be done using only binary
operations.


Next, we'll talk about sorting the digits of an integer.
