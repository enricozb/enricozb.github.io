#import "../../../typst/post.typ"
#import "../../../typst/inet.typ"
#import "../../../typst/inets.typ"
#import "@preview/cetz:0.3.4"

#show: content => post.post(
  title: "Lambda Calculus Normalization with Interaction Nets",
  date: "2025-04-25",
  content
)

#post.note[
  This will hopefully be the first in a series of posts on the theory and practice of using
  #link("https://en.wikipedia.org/wiki/Interaction_nets")[interaction nets] as a programming medium.

  This post assumes some familiarity with lambda calculus but none with interaction nets.
]

#let (era, con, dup) = inets.with-kinds(
  era: inets.nilary-node,
  con: inets.stroked-node,
  dup: inets.filled-node,
)

#let wire = inets.wire

= Overview
The purpose of this post is to introduce interaction nets to an audience familiar with lambda calculus. This post will
explain some of the general theory behind interaction nets and a particular instantiation of them with the purpose of
normalizing a subset of the lambda calculus. Lastly, we will explain the theoretical and practical benefits of using
such a system to normalize lambda calculus terms.

= Background

Lafont initially introduced interaction net systems in his 1990 paper,
#link("https://dl.acm.org/doi/pdf/10.1145/96709.96718")[_Interaction Nets_]. Interaction nets are a general
graph-rewriting system that allows one to define a set of node labels and rewrite rules, and in return provides some
guarantees on the "behavior" of normalizations of graphs under these rewrite rules. They are a generalization of
#link("https://en.wikipedia.org/wiki/Geometry_of_interaction")[Girard's Proof Nets], in the sense that proof nets
are an instance of an interaction net system. By way of this generalization, interaction nets are also intimately
related with #link("https://en.wikipedia.org/wiki/Linear_logic")[Linear Logic].

Interaction nets are a framework for describing a whole class of graph-rewriting systems. In
the context of modeling or encoding lambda calculus, one system that can be used is that of
the #link("https://www.sciencedirect.com/science/article/pii/S0890540197926432")[_Interaction
Combinators_], also devised by Lafont. The system we will describes below is a similar one known as the
#link("https://www-lipn.univ-paris13.fr/~mazza/papers/CombSem-MSCS.pdf")[_Symmetric Interaction Combinators_]
introduced by Mazza in 2007.

= Definitions & An Example Interaction Net System

== Nodes and Ports

An interaction net _system_ is a set of nodes (also called agents) that can occur in a net (or graph). Each node
has an ordered set of _ports_, which are where wires (or edges) can connect two nodes. Each node has a single
_principal port_, and the other ports, if any, are known as auxiliary ports. It's important to emphasize that the
auxiliary ports are ordered. For example, we can refer to the first or left auxiliary port of the nodes below when
looking at them at some fixed orientation.

Note that we deliberately confuse between discussing the _kinds_ of nodes (of which there are a fixed number
when discussing any given interaction system) and the _occurrences_ of nodes in a net (of which there can be
unboundedly many).

Let's define an example interaction system with three kinds of nodes:

#post.canvas({
  era("e", (0, 0), show-ports: true)
  con("c", (2, 0), show-ports: true)
  dup("d", (4, 0), show-ports: true)

  cetz.draw.content((0, -0.3), $epsilon$)
  cetz.draw.content((2, -0.1), $alpha$)
  cetz.draw.content((4, -0.1), text(white)[$delta$])
})

I've specifically drawn the nodes such that the pointy end of the triangle connected to a wire is that node's
principal port. The first/second auxiliary port is the left/right one when looking at the nodes in this orientation.

I'll name these nodes:
- Eraser ($epsilon$), which has no auxiliary ports.
- Constructor ($alpha$), which has two auxiliary ports.
- Duplicator ($delta$), which has two auxiliary ports.

The number of auxiliary ports of a node is also known as its _arity_. Extending that pattern, nilary nodes have
an arity of zero and binary nodes have arity two. In my opinion, drawing non-nilary (arity of at least zero)
nodes as triangles (with colors or text inside) make it clear which port is the principal port and which are the
auxiliary ports.

An example instance of a net in this three-node system could be:

#post.canvas({
  con("a", (0, 0))
  dup("b", (-0.5, -1.5))
  con("c", (-0, -3))

  wire("a.1", "b.0")
  wire("b.2", "c.0")
  wire("b.1", (-1, -3.1, -90deg), "c.1")
  wire("c.2", (1, -3, 90deg), "a.2")

  con("d", (1.5, 0))
  con("e", (1.5, -1.5))

  wire("a.0", "d.0")
  wire("e.0", "d.1")

  era("e1", (1.2, -2.7))
  era("e2", (1.8, -2.7))
  era("e3", (2, -1))

  wire("d.2", "e3.0")
  wire("e1.0", "e.1")
  wire("e2.0", "e.2")
})

I've omitted the greek-letter labels of the nodes, as they are uniquely identifiable by their shape and colors.

Notice that the distinction between principal and auxiliary ports does not restrict the construction of nets,
as wires can connect any kind of port to any other kind of port.

== Rewrite Rules

In order to perform any kind of computation with interaction nets, we need to define rewrite rules. The
restrictions in the kind of rules we can define are part of what bestows interaction nets their interesting
properties. Specifically: _rewrite rules only apply to -- and are uniquely identified by -- two nodes connected
by their principal ports_. Since these are the portions of the graph that can be rewritten or _reduced_, we call
them _reducible expressions_ or _active pairs_. Rewrite rules are also known as _interactions_.

The six (tersely written) rewrite rules we will be working with for the purpose of this post are as follows:

#post.canvas({
  con("comm-top", (0, 0), show-aux: true)
  dup("comm-bot", (0, 1.5), angle: 180deg, show-aux: true)
  wire("comm-top.0", "comm-bot.0", stroke: red)

  cetz.draw.content((1.2, 4/5), $arrow.long.squiggly$)

  con("comm'-1-top", (2.5, 1.5), show-main: true)
  con("comm'-2-top", (4, 1.5), show-main: true)
  dup("comm'-1-bot", (2.5, 0), angle: 180deg, show-main: true)
  dup("comm'-2-bot", (4, 0), angle: 180deg, show-main: true)

  wire("comm'-1-top.1", "comm'-1-bot.2")
  wire("comm'-2-top.2", "comm'-2-bot.1")
  wire("comm'-1-top.2", "comm'-2-bot.2")
  wire("comm'-2-top.1", "comm'-1-bot.1")
})

#post.canvas({
  con("comm-top-1", (0, 0), angle: 180deg, show-aux: true)
  era("comm-bot-1", (0, -1))
  wire("comm-top-1.0", "comm-bot-1.0", stroke: red)

  cetz.draw.content((1, -0.3), "or")

  dup("comm-top-2", (2, 0), angle: 180deg, show-aux: true)
  era("comm-bot-2", (2, -1))
  wire("comm-top-2.0", "comm-bot-2.0", stroke: red)

  cetz.draw.content((3.5, -0.3), $arrow.long.squiggly$)

  era("comm'-bot-1", (5, -1))
  wire("comm'-bot-1.0", (5, 0.7, 90deg))

  era("comm'-bot-2", (6, -1))
  wire("comm'-bot-2.0", (6, 0.7, 90deg))
})

#post.canvas({
  con("anni-top-1", (0, 0), angle: 180deg, show-aux: true)
  con("anni-bot-1", (0, -1.5), show-aux: true)
  wire("anni-top-1.0", "anni-bot-1.0", stroke: red)

  cetz.draw.content((1, -0.7), "or")

  dup("anni-top-2", (2, 0), angle: 180deg, show-aux: true)
  dup("anni-bot-2", (2, -1.5), show-aux: true)
  wire("anni-top-2.0", "anni-bot-2.0", stroke: red)

  cetz.draw.content((3.5, -0.7), $arrow.long.squiggly$)

  wire((5, 0.7, -90deg), (6, -2.3, -90deg))
  wire((6, 0.7, -90deg), (5, -2.3, -90deg))
})

#post.canvas({
  era("anni-top-3", (4, 0), angle: 180deg)
  era("anni-bot-3", (4, -1.5))
  wire("anni-top-3.0", "anni-bot-3.0", stroke: red)

  cetz.draw.content((5, -0.7), $arrow.long.squiggly$)

  cetz.draw.content((6, -0.7), "∅")
})

In these rules the left-hand side of the squiggly line describe a pair of nodes connected by their principal port
(colored in red). If such a pair is seen in a graph, it is rewritten to the right-hand side of the rule. The open
wires above and below each rule are connected to some other unrelated part of the net.

The first three rules are known as _commutations_, and the last three rules as _annihilations_. Commutations occur
when nodes of different kinds interact and annihilations occur when nodes of the same kind interact.

This system is known as 2-Symmetric Interaction Combinators, or 2-SIC. The "2" is because there are two binary nodes,
and the "symmetric" is because the annihilation interaction is the same regardless of whether we are annihilating
constructor or duplicator nodes.

It is in this system where we will encode and soundly evaluate a subset of the lambda calculus.

= Properties of Interaction Nets

== Strong Confluence

By restricting the rewrite rules to only apply to nodes that are connected via their principal ports, rewrites
are _local_. They can be performed independently of each other, as a single node can never be part of two reducible
expressions at the same time. Additionally, the rewrite rules cannot affect other existing active pairs. Specifically,
performing a rewrite will not cause any other existing active pair to no longer become active. This results in a
one-step diamond property known as _strong confluence_:

#post.canvas({
  cetz.draw.content((0, 2), $cal(N)$)
  cetz.draw.content((-0.5, 1.5), $arrow.l.long$, angle:  45deg)
  cetz.draw.content(( 0.5, 1.5), $arrow.r.long$, angle: -45deg)
  cetz.draw.content((-1, 1), $cal(P)$)
  cetz.draw.content(( 1, 1), $cal(Q)$)
  cetz.draw.content((-0.5, 0.5), $arrow.r.long$, angle: -45deg)
  cetz.draw.content(( 0.5, 0.5), $arrow.l.long$, angle:  45deg)
  cetz.draw.content(( 0, 0), $cal(R)$)
})

Assume that $cal(N)$ is some net. If $cal(N)$ can reduce to $cal(P)$ or $cal(Q)$ in a single step, and $cal(Q)
eq.not cal(P)$, $cal(P)$ and $cal(Q)$ can each reduce in a single step to $cal(R)$. This property results in the
astonishing fact: *the number of rewrites required to normalize an interaction net is independent of the order
of the rewrites*. This is not true of other term-rewriting systems such as lambda calculus, where the number of
beta-reductions that are performed to normalize a term will depend on the order of the rewrites.

== Aside: Practical Consequences & Hardware

Since the rewrite rules are local, and can be applied without affecting other parts of a net,
there is a clear potential for parallel reduction / normalization of interaction nets. Modern
computers are the result of huge investment in research with the goal of improving upon the
#link("https://en.wikipedia.org/wiki/Von_Neumann_architecture")[von Neumann architecture]. Normalization of interaction
nets doesn't necessarily fit well into this architecture, so modelling such a system is an area of ongoing research.

Additionally, software that is intended to perform interaction net reduction can choose to fix the _interaction net
system_ that is being reduced, as opposed to allowing the user to provide a set of nodes and rewrite rules. Programming
languages such as #link("https://vine.dev/")[Vine] and #link("https://github.com/HigherOrderCO/HVM")[HVM] both are
reduction engines of fixed interaction net systems stemming from Mazza's symmetric combinators.

GPU's also provide an interesting hardware medium to perform interaction net reduction. But again, the nuance here
is in designing an appropriate memory layout and algorithm to perform reduction in order to maximally realize the
theoretical benefits of interaction nets.

= Encoding Lambda Calculus Terms

== Translation

#let map(t) = $bracket.l.double #t bracket.r.double$

We've defined above an interaction system of three nodes (eraser, constructor, duplicator) and six rewrite rules. We
now need to create a translation or mapping from lambda calculus terms to interaction nets, such that beta-reduction
is respected after reinterpreting the normalized interaction net as a lambda calculus term. Let's call this mapping
$map(dot)$.

In order to define $map(dot)$, we need to define how it will act on all possible lambda terms. This can be done
inductively (recursively) over the two possible kinds of lambda terms, abstraction and application:

#post.canvas({
  cetz.draw.content((0, 0), $map(lambda x. t) = $)

  inet.con(name: "lam", pos: (3, 0))
  cetz.draw.content((2.2, -1.15), $x$)
  cetz.draw.content((3.5, -1.2), $map(t)$)
  inet.port("res-pos", (1, 0), dir: -90deg)
  inet.port("x-neg", (2.5, -1))
  inet.port("x-pos", (2.5, -1), dir: 180deg)
  inet.port("[t]-pos", (3.5, -0.9))
  inet.port("[t]-neg-1", (3.3, -1.5), dir: 180deg)
  inet.port("[t]-neg-2", (3.5, -1.5), dir: 180deg)
  inet.port("[t]-neg-3", (3.7, -1.5), dir: 180deg)

  inet.era(name: "era", pos: (3, -2), rot: 90deg)
  cetz.draw.content((3, -2.5), "or")
  inet.port("x-lin-neg", (3, -3), dir: 90deg)
  inet.port("x-lin-pos", (3, -3), dir: -90deg)
  cetz.draw.content((3, -3.5), "or")
  inet.dup(name: "dup", pos: (3, -4.5), rot: 90deg)
  // cetz.draw.content((2, -3.5), "or")

  inet.link("lam.0", "res-pos")
  inet.link("lam.1", "x-neg")
  inet.link("[t]-pos", "lam.2")
  inet.link("x-pos", "era.0", dash: "dashed")
  inet.link("x-pos", "x-lin-neg", dash: "dashed")
  inet.link("x-lin-pos", "[t]-neg-1", dash: "dashed")
  inet.link("x-pos", "dup.0", dash: "dashed")
  inet.link("dup.2", "[t]-neg-2", dash: "dashed")
  inet.link("dup.1", "[t]-neg-3", dash: "dashed")
})

#post.canvas({
  cetz.draw.content((0, 0), $map((f a)) = $)

  inet.con(name: "lam", pos: (3, 0))
  cetz.draw.content((2.5, -1.2), $map(a)$)
  cetz.draw.content((3, 1), $map(f)$)
  inet.port("res-pos", (1, 0), dir: -90deg)
  inet.port("res-mid-neg", (2.5, -2), dir: -90deg)
  inet.port("res-mid-pos", (2.5, -2), dir: 90deg)
  inet.port("a-neg", (2.5, -0.9))
  inet.port("[f]-pos", (3, 0.7), dir: 180deg)

  inet.link("lam.2", "res-mid-neg")
  inet.link("res-mid-pos", "res-pos")
  inet.link("lam.1", "a-neg")
  inet.link("[f]-pos", "lam.0")
})

There are a few things to digest here:

1. We are using an open or free wire to refer to the nets in the image of $map(dot)$.

2. The translation of abstraction and application both use the same kind of node, a constructor.

3. $x$ is not a node, we are just labeling a wire to more clearly show its purpose.

4. The dashed wire will connect to wherever $x$ is referenced in $t$. There are three scenarios to consider here:
    - if $x$ is not referenced in $t$, then connect it to an eraser node.
    - if $x$ is referenced once, connect it to where it's referenced.
    - if $x$ is referenced more than once, we need to stack duplication nodes as necessary until we have the same number
      of free auxiliary wires as references of $x$ in $t$. The number of interactions performed is independent of how we
      choose to arrange these duplication nodes, as every interaction consumes one $x$ and produces two.

== Translating an Example Term

Let's attempt a sample lambda calculus reduction using our 2-SIC translation $map(dot)$, specifically of the term
$(lambda f. (f f) lambda x. x)$. Using a friendlier function-definition syntax, the term we are interested in is
$thick "apply_self"(id) thin$ where

#post.center(
  $
    "apply_self"(f) &= f(f) \
    "id"(x) &= x
  $
)

We expect the reduction to result in $id$ or $lambda x. x$.

First, we must translate $med (lambda f. (f f) lambda x. x)$. There are two abstractions and one application, thus we need
three constructor nodes. We also use $f$ twice so we will need one duplication node. It's a good exercise to attempt this
translation yourself! Click below when you're ready to see how I've drawn it:

#post.spoiler(
  "click to show translated net",
  post.canvas({
    cetz.draw.content((0, 1), "")

    // left half
    inet.con(name: "a", pos: (0, 0))
    inet.dup(name: "b", pos: (-0.5, -1.5))
    inet.con(name: "c", pos: (-0, -3))

    inet.link("a.1", "b.0")
    inet.link("b.2", "c.0")

    cetz.draw.bezier("b.1.p", (-1/4, -3.44), (-1.5, -3), (-1/4, -4.5))
    cetz.draw.bezier("a.2.p", (1/4, -3.44), (1.5, -3), (1/4, -4.5))

    // right half
    inet.con(name: "d", pos: (1.5, 0))
    inet.con(name: "e", pos: (1.5, -1.5))

    inet.link("a.0", "d.0")
    inet.link("e.0", "d.1")

    cetz.draw.content((-2, -1.7), $lambda f. (f f)stretch(brace.l, size: #1100%)$)

    cetz.draw.bezier((1.2, -1.94), (1.8, -1.94), (1, -2.5), (2, -2.5))

    inet.port("x", (3, -1/3), dir: 180deg)
    inet.link("d.2", "x")

    cetz.draw.content((2.7, -1.8), $stretch(brace.r, size: #400%)lambda x. x$)
  })
)


The left "half" of this net is the translation of $lambda f. (f f)$, the right half includes application at the head
of the term, and the identity $lambda x. x$. The free wire is the resulting term after all interactions have been
performed.

== Reduction of an Example Term

In order to reduce this, we need to look at every active pair and apply the relevant rewrite rule. Again, like
the translation, this is a good exercise to attempt yourself and start building familiarity with how this graph
rewrite system behaves. Especially so with this example, as there is more than one possible reduction path.

Click below when you're ready to see how I reduced it! I'll color the active pairs about to be reduced in red
for clarity.

#post.spoiler("click to show the reduction steps")[

#post.canvas({
  cetz.draw.content((-2, 2), "")
  cetz.draw.content((-2, 1), "(1)")

  // left half
  inet.con(name: "a", pos: (0, 0))
  inet.dup(name: "b", pos: (-0.5, -1.5))
  inet.con(name: "c", pos: (-0, -3))

  inet.link("a.1", "b.0")
  inet.link("b.2", "c.0")

  cetz.draw.bezier("b.1.p", (-1/4, -3.44), (-1.5, -3), (-1/4, -4.5))
  cetz.draw.bezier("a.2.p", (1/4, -3.44), (1.5, -3), (1/4, -4.5))

  // right half
  inet.con(name: "d", pos: (1.5, 0))
  inet.con(name: "e", pos: (1.5, -1.5))

  inet.link("a.0", "d.0", main: true)
  inet.link("e.0", "d.1")

  cetz.draw.bezier((1.2, -1.94), (1.8, -1.94), (1, -2.5), (2, -2.5))

  inet.port("r", (2, -1), dir: 0deg)
  inet.link("d.2", "r")
})

#post.canvas({
  cetz.draw.content((-3, 1), "(2)")

  // left half
  inet.dup(name: "b", pos: (-0.5, -1.5))
  inet.con(name: "c", pos: (-0, -3))

  inet.link("b.2", "c.0")

  cetz.draw.bezier("b.1.p", (-1/4, -3.44), (-1.5, -3), (-1/4, -4.5))

  // right half
  inet.con(name: "e", pos: (-0.5, 0), rot: 180deg)

  inet.link("b.0", "e.0", main: true)

  cetz.draw.bezier((-1/4, 0.44), (-3/4, 0.44), (0.2, 1), (-1.2, 1))

  inet.port("r", (0.5, -4), dir: 0deg)
  inet.link("c.2", "r")
})

#post.canvas({
  cetz.draw.content((-2, 1), "(3)")

  // left half
  inet.dup(name: "d1", pos: (-0.5, 0))
  inet.dup(name: "d2", pos: (1, 0))
  inet.link("d1.0", "d2.0", main: true)

  inet.con(name: "c1", pos: (-0.5, -1.5), rot: 180deg)
  inet.con(name: "c2", pos: (1, -1.5), rot: 180deg)

  inet.link("c1.2", "d1.1")
  inet.link("c1.1", "d2.1")
  inet.link("c2.2", "d1.2")
  inet.link("c2.1", "d2.2")

  // right half
  inet.con(name: "c3", pos: (1, -3))
  inet.link("c3.0", "c2.0")
  cetz.draw.bezier((-0.5, -1.95), (0.8, -3.44), (-0.5, -4), (2/3, -4))

  // inet.link("c1.0", "c3.1")

  inet.port("r", (1.5, -4), dir: 0deg)
  inet.link("c3.2", "r")
})

#post.canvas({
  cetz.draw.content((-1, -0.5), "(4)")

  // left half
  inet.con(name: "c1", pos: (0.5, -4.5))
  inet.con(name: "c2", pos: (1, -1.5), rot: 180deg)
  inet.link("c1.1", "c1.2")
  inet.link("c2.1", "c2.2")

  // right half
  inet.con(name: "c3", pos: (1, -3))
  inet.link("c3.0", "c2.0", main: true)
  inet.link("c1.0", "c3.1")

  inet.port("r", (1.5, -4), dir: 0deg)
  inet.link("c3.2", "r")
})

#post.canvas({
  cetz.draw.content((-2, 0.5), "(5)")

  // left half
  inet.con(name: "c1", pos: (0, -1))
  inet.link("c1.1", "c1.2")

  inet.port("r", (0, 0), dir: 0deg)
  inet.link("c1.0", "r")
})

]

Some interesting things to note:
- This reduction took 4 steps. Every other possible reduction path will also -- by strong confluence -- take 4 steps.
- At step (3), there are actually two active pairs, and either one can be reduced.
- Intermediate nets -- such as the one in step (3) -- are not necessarily interpretable as lambda calculus terms.
- The normalized net is equivalent to the encoding of $lambda x. x$, which is what we expected.

== Limits of This Encoding

One important point to mention about this encoding is that _it does not soundly normalize all lambda calculus
terms_. Specifically, duplicating a function that duplicates its argument will not necessarily result in the same
term when reduced in lambda calculus (and may not result in a lambda calculus term at all). This is due to the fact
that duplication nodes annihilate each other when interacted, instead of duplicating each other.

You cannot simply change this interaction however. The annihilation of duplication nodes is important for sound
normalization of lambda calculus terms, and is a rule we used above in our sample reduction when duplicating the
identity function. There are multiple routes towards remedying this, and I plan on discussing them in another post.

Additionally, "garbage collection" here is explicit. Throwing away a variable (connecting it to an eraser) explicitly
destroys it. Because of how the interactions are defined however, the discarded term _will be normalized_. This is
because the eraser node can only interact with nodes through their active port, so any active pairs inside of the erased
term will be reduced before erasure. This is in contrast to the naive term-rewriting of lambda calculus, where a
substitution into an unused variable simply causes the term to "disappear". In some sense, unnecessary work may be
performed. In other sense however, it's optimal.

= What's the point?

== Lévy/Beta-Optimality

When normalizing lambda calculus terms via a traditional term-rewriting system, one might duplicate an unnormalized
term, thereby duplicating the amount of work required to further reach the fully normalized term. Jean-Jacques
Lévy defined a "minimum" number of beta-reductions required to normalize any lambda calculus term in his 1978
PhD thesis, #link("https://pauillac.inria.fr/~levy/pubs/78phd.pdf")[Réductions correctes et optimales dans le
lambda calcul].  His definition of a minimum was essentially the number of unique beta-reductions required to
normalize the term. Duplicated reducible expressions (unnormalized beta-reductions) are not double counted. It is
against this minimum that one can compare different lambda calculus reduction techniques. *With respect to Lévy's
definition of the minimum number of beta-reductions, the reduction of lambda calculus terms via interaction nets with
the above encoding is optimal*.

The beta-optimality of interaction nets is owed to the fact that abstractions are duplicated _incrementally_. If
one looks closely at the interaction net reduction of an abstraction being duplicated, they will notice that the
duplication node passes _through_ the abstraction node. The abstraction is duplicated into two, but the body is shared.

Beta-optimality does not imply that computational complexity (in terms of term size) of
this algorithm is superior to that of other lambda calculus normalizers -- such as Haskell's
#link("https://dl.acm.org/doi/pdf/10.1145/99370.99385")[Spineless Tagless G-Machine]. This is for two main reasons:
- Counting beta-reductions is nuanced when leaving the traditional term-rewriting system of lambda calculus.
- Counting beta-reductions alone does not account for other work being done.

For example, in the interaction net case, beta-reductions are probably most honestly represented as the number
of interactions between two constructor nodes, one for an abstraction and the other for an application. All
of the other interactions, however, will not be counted by this metric. In the case of Haskell's STG,
#link("https://fa.haskell.narkive.com/CJCnS0nS/haskell-cafe-counting-beta-reductions-for-a-haskell-program")[it's
also not obvious] how to compute the number of beta-reductions required to terminate the program.

== John Lamping

This encoding of lambda calculus terms and the algorithm for reduction is actually equivalent to a portion of an
algorithm presented by John Lamping's 1990 paper #link("https://dl.acm.org/doi/pdf/10.1145/96709.96711")[_An Algorithm
for Optimal Lambda Calculus Reduction_]. Astonishingly, it seems that this paper and the development of interaction
nets were independent, as Lamping mentions neither Lafont or Girard. The main difference (or omission) of the algorithm
presented in this post and Lamping's is the lack of _bracket nodes_. These nodes are one way to resolve the duplication
issue mentioned above.

= Conclusion & Other Topics

Hopefully you've gotten a taste of what interaction nets can offer, at least with respect to lambda calculus.
I personally find their theory very rich and distinct from anything else I've seen. As mentioned in the introduction,
this is intended to be a series, and I'm hoping to cover topics such as:

- lazy and strict symmetric interaction combinator reduction algorithms and their trade-offs
- a type system to ensure soundness of reducing an encoding of (an extended) lambda calculus
- theoretical bounds on the best and worst-case complexity of a beta-optimal lambda calculus evaluator
- polarized interaction systems
