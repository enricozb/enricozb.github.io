[title] EZB - Functions

[post_title] Functions 1
[post_subtitle] Introduction

[prev_post] ezb.io/thoughts
[next_post] functions_2.html

[body]

Somewhere in my senior year of high school, two friends and I were
wondering how one could write `min(x,y)` in math
notation using only binary operations and elementary functions. It took
us a little while to come up with something, but eventually we got this:

$$ \min(x, y) = \frac{x + y}{2} - \frac{\lvert x - y \rvert}{2} $$

This first part of this function finds the midpoint between $x$ and $y$.
Then, we travel half the distance between $x$ and $y$ toward $-\infty$, thus
arriving at the smaller of the two numbers. It's pretty clear that
`max(x,y)` can be achieved by travelling toward
$+\infty$ instead of toward $-\infty$, like so:

$$ \max(x, y) = \frac{x + y}{2} + \frac{\lvert x - y \rvert}{2} $$

Curious to perform this "mathematical translation" on other
functions commonly used in programing, we wondered how this could be done
for equality, $\text{eq}(x,y)$.  Since we wanted to stick to functions on
the reals, we opted for `true` being $1$, and
`false` being $0$. Here's what one of us came up with,

$$ \text{eq}(x, y) = 1 - \left\lceil \frac{\lvert x - y \rvert}{\lvert x - y \rvert + 1} \right\rceil $$

Using the celing function might seem like "cheating", but
it's important to remember that we were mostly trying to sidestep
functions defined in a piecewise/pattern-matching fashion. Thus, this
one-line arithmetic definition met our needs.


We kept going. Another useful function is `sign(x)`,
also known as `signum(x)`, that returns $-1$ if $x$ is
negative, $1$ if $x$ is positive, and $0$ if $x$ is $0$. Here's what we
came up with,

$$ \text{sign}(x) = \left\lfloor \frac{x}{\lvert x \rvert + 1} \right\rfloor +
    \left\lceil \frac{x}{\lvert x \rvert + 1} \right\rceil $$

Now, what's the point of doing all of this? Well, for me it was the fact
that in programming, arguments to a function (even as numbers) are
data, stored sequentially in memory. This mindset allows for easier
conceptualization of some operations over others. For example, how would
you write some code to reverse a number? Well, if the number was stored
in base 10 in memory, and not in binary, you could just copy the data
but in reverse order. Now, as a preview of what is to come,
**how would you write a math function to reverse an integer?**

When I was first working on this stuff, the idea
of treating math functions in this way was pretty foreign and made me
very curious about what was possible. Control flow, time and
space complexity, a sequence of instructions, all of that was gone when
writing using just arithmetic operations. In math, things just *are*.

I understand now that this really isn't any ground-breaking math nor
does it connect two fields in any novel way, but it was what I _thought_
was math, and that's what made me thoroughly enjoy the journey. I hope
you enjoy it too.

Let's talk about reversing an integer next.

