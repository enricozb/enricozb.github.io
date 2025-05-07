#import "../../../typst/post.typ"
#import "../../../typst/inets.typ"
#import "@preview/cetz:0.3.4"

#show: content => post.post(
  title: "Polarized Interaction Net Systems",
  date: "2025-05-05",
  content
)

#post.note[
  This is the second post in a series on the theory and practice of using
  #link("https://en.wikipedia.org/wiki/Interaction_nets")[interaction nets] as a programming medium.

  Please read the #link("2025-04-25_normalization.html")[first post] if you are unfamiliar with interaction nets.
]

#let (era, con, dup) = inets.with-kinds(
  era: inets.nilary-node,
  con: inets.stroked-node,
  dup: inets.filled-node,
)

#let wire = inets.wire

#let map(t) = $[| #t |]$

= Overview

In this post we will introduce _polarized interaction systems_. These can be seen as a very simple type system
on interaction nets that restricts which nets we can consider valid. We'll then use this notion to more clearly
understand the 2-SIC encoding.  Then, we'll use polarity to understand how we can _read back_ interaction nets as
lambda calculus terms. Finally, we'll see that there is a natural extension of lambda calculus by expanding how
we interpret interaction nets as lambda calculus terms.

= Readback

== Motivation

Previously, we introduced the 2-SIC system as a way to encode and reduce a subset of the lambda calculus. One critical
point we glossed over is how we translate normalized interaction nets back into lambda calculus terms. This process is
known as _read back_.

This algorithm is not immediately intuitive because we encode different lambda calculus constructs into the same kind
of node. For example, consider the following normalized interaction net:

#post.canvas(caption: "A normalized 2-SIC net", label: "normalized", {
  con("a", (0, 0), show-main: true)
  con("b", (1, -1.5))
  con("c", (0.5, -3))

  cetz.draw.content("a.label", $A$)
  cetz.draw.content("b.label", $B$)
  cetz.draw.content("c.label", $C$)

  wire("a.1", (-0.5, -3, -90deg), "c.1")
  wire("a.2", "b.0")
  wire("b.1", "c.0")
  wire("c.2", (1.5, -3, 90deg), "b.2")
})

How do we know what lambda calculus term this net represents? Let's try understanding what lambda calculus term
is at the head of this net. That is, is node $A$ an abstraction or an application?

== Intuition

Ignoring erasures and duplications for a moment, let's recall our 2-SIC translation $map(dot)$ which maps lambda calculus terms
to 2-SIC nets:

#post.canvas({
  cetz.draw.content((0, 0), $map(lambda x. t) =$)

  con("a", (2, 0))
  cetz.draw.content((2.5, -1.5), $map(t)$)

  wire("a.0", (1, 0, 180deg))
  wire("a.1", (2.1, -1.5, 0deg))
  wire((2.5, -1.1, 90deg), "a.2")

  cetz.draw.content((1.4, -1), $x$)
})

#post.canvas(caption: "2-SIC translation (ignoring erasure & duplication)", {
  cetz.draw.content((0, 0), $map((f a)) = $)

  con("lam", (3, 0), show-main: true)
  cetz.draw.content((2.5, -1.5), $map(a)$)

  wire("lam.1", (2.5, -1.1, -90deg))
  cetz.draw.content((3, 1), $map(f)$)

  wire("lam.2", (2.5, -2.5, 180deg), (1, 0, 180deg))
})

From looking at the definition of our translation, can you now tell which lambda calculus term is at the head of
the net in @normalized?

The head of the term in @normalized _has_ to be an abstraction: $lambda x. t$. This is because the term is identified
by the principal port of a constructor node. In a constructor node representing an application, the principal port
_consumes_ a function. So, this port _cannot_ be used to refer to the head of any lambda calculus term, as there is no
notion of an expectation of a term in lambda calculus.

On the other hand, the principal port of a constructor node representing an abstraction _produces_ a lambda calculus
term. Thus, this port _can_ be used to refer to the head of a lambda calculus term.

The formalization of ports either producing or consuming terms is _polarization_.

= Polarized Interaction Systems

== Polarizing SIC Nodes
A _polarized_ interaction system is a refinement of an interaction system. For each kind of node, we define
(possibly multiple) classifications of its ports as either producers or consumers.

In #link("https://franchufranchu.github.io/answers/single-pass-read back/")[Franchu's post on read back], polarization
is described as a labeling of ports as "positive" or "negative", where positive ports are producers and negative
ports are consumers. While I will also use this terminology here, I find it very useful to draw polarity
using arrows, where the direction goes from negative to positive.

For each of the three 2-SIC nodes, we will have two possible polarizations:

#post.canvas(caption: "Polarized 2-SIC", {
  era("nul", (0, 0), show-ports: true, polarities: (1,))
  era("era", (1, 0), show-ports: true, polarities: (-1,))
  con("app", (3, 0), show-ports: true, polarities: (-1, -1, 1))
  con("lam", (4.5, 0), show-ports: true, polarities: (1, 1, -1))
  dup("dup", (6.5, 0), show-ports: true, polarities: (-1, 1, 1))
  dup("sup", (8, 0), show-ports: true, polarities: (1, -1, -1))

  cetz.draw.content("nul.label", $nu$)
  cetz.draw.content("era.label", $epsilon$)
  cetz.draw.content("app.label", $alpha$)
  cetz.draw.content("lam.label", $lambda$)
  cetz.draw.content("dup.label", text(white, $delta$))
  cetz.draw.content("sup.label", text(white, $sigma$))
})

Note that these labels are just to identify the polarizations, _there are still only three kinds of nodes_:

#post.canvas(caption: "2-SIC nodes", {
  era("era", (0, 0), show-ports: true)
  con("con", (2, 0), show-ports: true)
  dup("dup", (4, 0), show-ports: true)
})

Some things to note:
- The rewrite rules are unchanged.
- Each polarization has a dual (e.g. $thick alpha <-> lambda, delta <-> sigma$), where the polarization of each wire is
  flipped.
- An outgoing arrow can be seen as producing a value.
- An incoming arrow can be seen as consuming a value.
- The Greek letters are intended to refer to the following names in English:
  - $nu$: Null
  - $epsilon$: Erasure
  - $alpha$: Application
  - $lambda$: Abstraction
  - $delta$: Duplication
  - $sigma$: Superposition

== An Example Polarized Term

Let's look at the polarization of the term discussed in the previous post, $thin thin (lambda f. (f f) lambda x. x)$:

#post.canvas(caption: "Example polarized term", {
  // left half
  con("a", (0, 0))
  dup("b", (-0.5, -1.5))
  con("c", (0, -3))

  cetz.draw.content("a.label", $lambda$)
  cetz.draw.content("b.label", text(white, $delta$))
  cetz.draw.content("c.label", $alpha$)

  wire("a.1", "b.0", polarize: 0.7)
  wire("b.2", "c.0", polarize: 0.7)
  wire("b.1", (-1, -3, -90deg), "c.1", polarize: 0.5)
  wire("c.2", (1,  -3,  90deg), "a.2", polarize: 0.7)

  // cetz.draw.bezier("b.1.p", (-1/4, -3.44), (-1.5, -3), (-1/4, -4.5))
  // cetz.draw.bezier("a.2.p", (1/4, -3.44), (1.5, -3), (1/4, -4.5))

  // right half
  con("d", (1.5, 0))
  con("e", (1.5, -1.5))

  cetz.draw.content("d.label", $alpha$)
  cetz.draw.content("e.label", $lambda$)

  wire("a.0", "d.0", polarize: true)
  wire("d.2", (3, -calc.sqrt(3)/4, 90deg), polarize: 1)
  wire("e.0", "d.1", polarize: 0.6)
  wire("e.1", "e.2", polarize: 0.7)

  cetz.draw.content((-2, -1.7), $lambda f. (f f) stretch(brace.l, size: #1100%)$)
  cetz.draw.content((2.7, -1.8), $stretch(brace.r, size: #400%) lambda x. x$)
})

While I've labeled nodes with their polarization symbols ($alpha$, $lambda$, etc.), these labels can be inferred by
inspecting the polarization alone, given that the _lone free wire is positive_. This is the essence of reading 2-SIC
nets back as lambda calculus terms.

== An Algorithm for Readback

Since we _always_ identify terms through an open wire at the positive end, we can always infer the polarizations of
the nodes in the entire net. This is because if we know the polarity of a single port and the kind of 2-SIC node
(eraser, constructor, duplication) we are looking at, then we also know the polarization of the entire node. This
is precisely due to the fact that each kind of node has two dual polarizations. If there were more polarizations for
a given kind of node, we would not necessarily be able to infer the polarization of the entire node knowing only
a single port's polarity. Knowing a node's polarization then also lets us know which lambda calculus construct the
node corresponds to.

This algorithm for readback is of course specific to 2-SIC, but can also be applied in other contexts where polarity
is relevant.

= Understanding the 2-SIC Polarizations

== Abstraction and Application

Let's go through abstraction and application polarizations first, as I believe these to be the most intuitive. In
lambda calculus, the term $(f x)$ is an application that consumes two terms, $f$ and $x$, and produces one. Thus,
we expect two ports with incoming arrows (negative) and one port with an outgoing arrow (positive):

#post.canvas(caption: "Application", {
  con("app", (0, 0), show-ports: true, polarities: (-1, -1, +1))
  cetz.draw.content("app.label", $alpha$)

  cetz.draw.content((0, 1.2), $f$)
  cetz.draw.content((-0.3, -1.1), $x$)
})

The reason for the principal port of the constructor node to receive the function -- as opposed to one of the
auxiliary ports -- is to create an active pair or reducible expression when $f$ is an abstraction. That is, we
want the lambda calculus term $(f x)$ to be translated into an active pair when a beta-reduction is possible,
which is only when $f$ is an abstraction.

When encoding an application, we connect the single positive wire to the occurence of the abstraction in the net.

Dually, an abstraction $lambda x. t$ consumes a term $t$ but it produces _two_, $x$ and $lambda x. t$:

#post.canvas(caption: "Abstraction", {
  con("lam", (0, 0), show-ports: true, polarities: (+1, +1, -1))
  cetz.draw.content("lam.label", $lambda$)

  cetz.draw.content((+0.3, -1.1), $t$)
  cetz.draw.content((-0.3, -1.1), $x$)
})

While it might be strange to see a variable $x$ described as a term, $x$ can be placed anywhere a term can, and thus
can be seen as one.

Similarly to applications, when encoding an abstraction, we connect the single positive wire to the occurence of
the abstraction in the net.

== Erasure and Duplication

Erasure and duplication are two more polarizations of nodes that are in the image of our 2-SIC translation
$map(dot)$. For example, erasers appear when we create abstractions that do not use their variables:

#post.canvas(caption: "Example erasure", {
  cetz.draw.content((0, 0), $map(lambda x. lambda y. y) =$)

  con("a", (3, 0))
  con("b", (4, -1.5))
  era("e", (2, -1.5))

  cetz.draw.content((2.7, -1), $x$)
  cetz.draw.content((4, -2.6), $y$)

  cetz.draw.content("a.label", $lambda$)
  cetz.draw.content("b.label", $lambda$)
  cetz.draw.content("e.label", $epsilon$)

  wire("a.0", (1.2, 0, 180deg), polarize: 1)
  wire("b.0", "a.2", polarize: true)
  wire("a.1", "e.0", polarize: true)
  wire("b.1", "b.2", polarize: true)
})

And duplications appear when using a variable more than once:

#post.canvas(caption: "Example duplication", {
  cetz.draw.content((0, 0), $map(lambda x. (x x)) =$)

  con("a", (3, 0))
  con("b", (3.5, -2))
  dup("d", (2, -1.5))

  cetz.draw.content("a.label", $lambda$)
  cetz.draw.content("b.label", $alpha$)
  cetz.draw.content("d.label", text(white, $delta$))

  wire("a.0", (1.2, 0, 180deg), polarize: 1)
  wire("a.1", "d.0", polarize: true)
  wire("d.1", "b.1", polarize: true)
  wire("d.2", "b.0", polarize: true)
  wire("b.2", (4.3, -2, 90deg), "a.2", polarize: true)
})

In terms of producers and consumers, erasure is a consumer. It is -- sensibly -- not a value. Duplication, however, is
both a consumer and a producer. It produces two values, which also makes sense as it consumes its argument to produce
two copies of it.

== Null

In a type system for the lambda calculus, if a term is well-typed, intermediate terms found during reduction are
also well-typed. Ideally, valid polarized nets should also have a similar property: if an initial net is valid,
all intermediate nets during reduction should also be valid. At a minimum, this can be used to read back nets _during_
reduction, and not only _after_ it.

The problem here is that the four polarizations we have detailed above (abstraction, application, erasure, and
duplication) are not sufficient to obtain this property. For example, when erasing the identity function $lambda x. x$:

#post.canvas({
  era("e", (0, 0), angle: -90deg)
  con("l", (1, 0), angle: +90deg)

  wire("l.0", "e.0", polarize: true)
  wire("l.1", "l.2", polarize: 0.55)

  cetz.draw.content("l.label", $lambda$)
  cetz.draw.content("e.label", $epsilon$)
})

#post.canvas({
  cetz.draw.content((0, 0), $~~>$, angle: -90deg)
})

#post.canvas(caption: "A positive eraser", {
  era("e1", (0, -2), angle: -90deg)
  era("e2", (0, -3), angle: -90deg)
  wire("e2.0", (1.5, -2.5, 90deg), "e1.0", polarize: 0.82)
  wire("e2.0", (1.5, -2.5, 90deg), "e1.0", polarize: 0.20)

  cetz.draw.content("e1.label", $epsilon$)
  cetz.draw.content("e2.label", $?$)
})

This intermediate term has an eraser node with a negative polarity, but on the other end is also an eraser node,
which thus must have a positive polarity. Nets with a positive free port can be seen as values. This positive
eraser can be interpreted as a new kind of term that represents a "null" value. It's important to emphasize that
this positive eraser does not appear when translating lambda calculus terms, only when reducing them.

== Superposition

Duplication nodes have a similar situation. When duplicating the identity function, the commutation rewrite rule
necessarily results in two duplication nodes that have opposite polarities:

#post.canvas({
  dup("d", (0, 0), angle: -90deg, show-aux: true, polarities: (-1, +1, +1))
  con("l", (1.5, 0), angle: +90deg)

  wire("l.0", "d.0", polarize: true)
  wire("l.1", "l.2", polarize: true)

  cetz.draw.content("l.label", $lambda$)
  cetz.draw.content("d.label", text(white, $delta$))
})

#post.canvas({
  cetz.draw.content((0, 0), $~~>$, angle: -90deg)
})

#post.canvas(caption: "Duplicating the identity function", {
  con("l1", (0, 0), angle: +90deg, show-main: true, polarities: (+1, -1, -1))
  con("l2", (0, 1.5), angle: +90deg, show-main: true, polarities: (+1, -1, -1))

  dup("d1", (2, 1.5), angle: -90deg)
  dup("d2", (2, 0), angle: -90deg)

  wire("l1.1", "d2.2", polarize: true)
  wire("d1.2", "l1.2", polarize: 0.75)
  wire("l2.1", "d2.1", polarize: 0.3)
  wire("d1.1", "l2.2", polarize: true)
  wire("d2.0", "d1.0", polarize: 0.55)

  cetz.draw.content("l1.label", $lambda$)
  cetz.draw.content("l2.label", $lambda$)
  cetz.draw.content("d1.label", text(white, $delta$))
  cetz.draw.content("d2.label", text(white, $?$))
})

This intermediate term has two duplication nodes connected via their principal port. They therefore must have
different polarizations. When looking at this dual of the duplication node, it consumes two values and produces
one, but the consumed values are symmetric. That is, both of the consumed values go into aux ports, unlike the
in an application where one consumed value goes into an aux port and one into a principal port. Because of the
commutation rules, this can be seen as a single term with two values, or a superposition.

= Extending Lambda Calculus

== Null and Superpositions as Terms

As we saw above, there are two polarizations that are only present in intermediate nets. What if we allowed for these
polarizations to appear in the image of $map(dot)$? That would require us to add some new lambda calculus terms that
map to null values (positive erasers), and superpositions (dual of duplication).

Null values can be described as a term $*$ with an additional beta-reduction rule:

$
(* t) ~~> *
$

This is very similar to a bottom term $bot$ as it "infects" or "destroys" the computation.

Superpositions are a new term ${f g}$ with the following beta-reduction rule#footnote[As mentioned in the previous
post, the 2-SIC encoding does not soundly evaluate the full set of terms of lambda calculus. Similarly, the
extension of lambda calculus with superpositions is not fully soundly evaluated by 2-SIC due to the same issue
of undesired duplication / superposition interactions. Specifically, duplicating a superposition results in each
fresh variable receiving one argument of the superposition, instead of the superposition itself being duplicated.]:

$
({f g} t) ~~> {(f t) (g t)}
$

Superpositions are especially interesting as they are like a pair but with some auto-vectorization properties.
Specifically, applying a superposition of functions to an argument reduces to a superposition of applications.
Additionally, applying a function to a superposition of arguments is equivalent#footnote[Equivalence is a bit
too nuanced to present in a footnote. A naive/incomplete definition could be: lambda calculus terms $x$ and $y$
are equivalent if substituting one for the other in any term results in the same result. This hopefully gives you
some intuition of what is intended here.] to a superposition of applications:

$
(f {x y}) approx {(f x) (f y)}
$

== Aside: Unscoped Lambdas

Yet another extension -- that doesn't really come out of polarity -- is that of _unscoped lambdas_. I'd like to
discuss these more deeply at some point, but in short: interaction nets do not require you to connect the wire of
an abstraction's variable to somewhere in its body. You are free to connect them anywhere else in the net, resulting
in a sort of "use-once channel" where data can be sent and read. A term like this for example:

#post.canvas(caption: "An unscoped lambda term", {
  wire = wire.with(polarize: 0.7)

  cetz.draw.content((0, 0), $map((lambda hat(x). * lambda y. hat(x))) =$)

  con("lam1", (3, -1.5))
  con("lam2", (3.5, 1.5), angle: 180deg)
  con("app", (3, 0), angle: 180deg)
  era("era", (4, 2.8), angle: 180deg)
  era("nul", (3.5, -3))

  cetz.draw.content("app.label", $alpha$)
  cetz.draw.content("lam1.label", $lambda$)
  cetz.draw.content("lam2.label", $lambda$)
  cetz.draw.content("nul.label", $nu$)
  cetz.draw.content("era.label", $epsilon$)

  wire("app.2", (1.5, 0, 180deg), polarize: 1)
  wire("lam1.0", "app.0")
  wire("lam2.0", "app.1", polarize: 0.65)
  wire("lam2.1", "era.0")
  wire("nul.0", "lam1.2")
  wire("lam1.1", (3.5, -4, 0deg), (4.5, 0, 90deg), (4.2, 3.5, 180deg), "lam2.2", polarize: 0.5)

  cetz.draw.content((4.2, 0), $hat(x)$)
})

where $hat(x)$ is an _unscoped variable_ that is being referenced outside of this body. Can you figure out what this term
normalizes to? Try normalizing the interaction net and reading back the result.

= Conclusion

We've seen how polarity can be used to read back interaction nets as lambda calculus terms, by uniquely identifying
which lambda calculus constructs correspond to which nodes. We've also seen that there are some additional polarizations
of nodes that are not present in the image of our 2-SIC translation. These two additional polarizations can be used to
extend the lambda calculus with some new interesting terms.

I'd like to eventually extend the discussion on superpositions to how they can be used -- along with the beta-optimal
properties of interaction nets -- to efficiently perform program search.
