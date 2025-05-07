#import "../../../typst/post.typ"
#import "../../../typst/inets.typ"
#import "@preview/cetz:0.3.4"

#show: content => post.post(
  title: "Lazy and Strict Evaluation",
  date: "2025-05-25",
  content
)

#post.note[
  This is the third post in a series on the theory and practice of using
  #link("https://en.wikipedia.org/wiki/Interaction_nets")[interaction nets] as a programming medium.

  Please read the #link("2025-04-25_normalization.html")[first post] if you are unfamiliar with interaction nets,
  and/or the #link("2025-05-05_polarity.html")[second post] for an introduction to polarity.
]

#let (era, con, ref) = inets.with-kinds(
  era: inets.nilary-node,
  con: inets.stroked-node,
  ref: inets.reference-node,
)

#let wire = inets.wire

= Overview

There are currently two main algorithms for normalizing interaction nets: lazy evaluation and strict evaluation. We'll
see that these two algorithms are somewhat at odds with each other. Specifically, strict evaluation is highly
parallelizable, while lazy evaluation can handle a larger class of infinite nets. In order to understand this
difference, we'll have to introduce a new family of interaction systems, $k$-SIC with reference nodes.

= $k$-SIC + References

$k$-SIC is natural extension of 2-SIC, where we have $k$ different kinds of binary nodes that annihilate when
they are of the same kind, and commute when they are of different kinds. Additionally, we're going to add a new
kind of node known as a _reference_ node. This is a deferred reference to a named net, which will be copied or
expanded when interacted with. The set of names $cal(R)$ is fixed.

Specifically, the kinds of nodes now looks like:

#post.canvas(caption: [$k$-SIC + reference nodes], {
  era("e", (0, 0), show-ports: true)
  con("c", (2, 0), show-ports: true)
  ref("r", (4, 0), show-ports: true)

  cetz.draw.content("c.label", $i$)
  cetz.draw.content("r.label", $r$)

  cetz.draw.content((2, -1.5), $i in {1, .., k}$)

  cetz.draw.content((4, -1.45), $r in cal(R)$)
})

And we have the rewrite rules: TODO

= Infinite Nets

Recursive -- or mutually recursive -- use of the new reference node allows for the construction of infinite nets. For
example:

#post.canvas({
  cetz.draw.content((0, 0), $"foo" :=$)

  con("l", (2, 0))
  era("e", (1, -1))
  ref("r", (3, -1.2))

  wire("l.0", (0.7, 0, 180deg))
  wire("l.1", "e.0")
  wire("r.0", "l.2")

  cetz.draw.content("r.label", $"foo"$)
})

Which represents the net: TODO

This reference node is a way to introduce laziness into a strict context, as references are only expanded when
interacted with.

- strict alg: perform every interaction even if it doesn't not contribute to the eventually normalized result.
- lazy alg: perform interactions only found during graph traversal which are guaranteed to affect final result.

= Lazy Evaluation

== Determining Necessary Interactions through Graph Traversal
