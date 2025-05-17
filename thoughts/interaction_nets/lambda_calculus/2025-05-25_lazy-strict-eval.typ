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
parallelizable and has garbage collection for free, while lazy evaluation can normalize a larger class of
terms. In order to understand this difference, we'll have to introduce a new family of interaction systems:
$k$-SIC with reference nodes.

= $k$-SIC + References

$k$-SIC is natural extension of 2-SIC, where we have $k$ different kinds of binary nodes that annihilate when
they are of the same kind, and commute when they are of different kinds. Additionally, we're going to add a new
kind of node known as a _reference node_. This is a deferred reference to a named net, which will be copied when
interacted with. Named nets must have a free wire#footnote[much like how our translations of lambda calculus terms
would refer to nets through a free wire]. The set of names $cal(R)$ is fixed.

For the remainder of the post, we'll refer to this interaction system as simply $k$-SIC without explicitly mentioning
the addition of reference nodes every time.

The kinds of nodes now looks like:

#post.canvas(caption: [$k$-SIC nodes], {
  era("e", (0, 0), show-ports: true)
  con("c", (2, 0), show-ports: true)
  ref("r", (4, 0), show-ports: true)

  cetz.draw.content("c.label", $i$)
  cetz.draw.content("r.label", $r$)

  cetz.draw.content((2, -1.5), $i in {1, .., k}$)

  cetz.draw.content((4, -1.45), $r in cal(R)$)
})

And we have the following rewrite rules:

#post.canvas({
  con("i", (0, 0), show-aux: true)
  con("j", (0, 1.5), angle: 180deg, show-aux: true)
  wire("i.0", "j.0", stroke: red)

  cetz.draw.content("i.label", $i$)
  cetz.draw.content("j.label", $j$)

  cetz.draw.content((1.2, 4/5), $~~>$)

  con("i'-1", (2.5, 1.5), show-main: true)
  con("i'-2", (4, 1.5), show-main: true)
  con("j'-1", (2.5, 0), angle: 180deg, show-main: true)
  con("j'-2", (4, 0), angle: 180deg, show-main: true)

  cetz.draw.content("i'-1.label", $i$)
  cetz.draw.content("j'-1.label", $j$)
  cetz.draw.content("i'-2.label", $i$)
  cetz.draw.content("j'-2.label", $j$)

  wire("i'-1.1", "j'-1.2")
  wire("i'-2.2", "j'-2.1")
  wire("i'-1.2", "j'-2.2")
  wire("i'-2.1", "j'-1.1")

  cetz.draw.content((-1.5, 4/5), $(i eq.not j)$)

  cetz.draw.content((5.5, 4/5), $(1)$)
})

#post.canvas({
  con("j", (0, 0), angle: 180deg, show-aux: true)
  con("i", (0, -1.5), show-aux: true)
  wire("i.0", "j.0", stroke: red)

  cetz.draw.content("i.label", $i$)
  cetz.draw.content("j.label", $j$)

  cetz.draw.content((1.2, -0.7), $~~>$)

  wire((2, 0.7, -90deg), (3, -2.3, -90deg))
  wire((3, 0.7, -90deg), (2, -2.3, -90deg))

  cetz.draw.content((-1.5, -0.7), $(i = j)$)

  cetz.draw.content((5.5, -0.7), $(2)$)
})

#post.canvas({
  con("i", (0, 0), angle: 180deg, show-aux: true)
  ref("r", (0, -1.5))
  wire("i.0", "r.0", stroke: red)

  cetz.draw.content("i.label", $i$)
  cetz.draw.content("r.label", $r$)

  cetz.draw.content((1.2, -0.7), $~~>$)

  con("i'", (2.5, 0), angle: 180deg, show-aux: true)

  cetz.draw.circle((2.5, -1.5), radius: 0.5, stroke: (dash: "dashed"))

  wire("i'.0", (2.5, -1, -90deg))

  cetz.draw.content("i'.label", $i$)
  cetz.draw.content((2.5, -1.5), $r$)

  // hidden so the widths of the diagrams are the same
  cetz.draw.content((-1.5, -0.7), hide($(i = j)$))

  cetz.draw.content((5.5, -0.7), $(3)$)
})

#post.canvas({
  ref("r-1", (0, 0), angle: 180deg)
  ref("r-2", (0, -1.5))
  wire("r-1.0", "r-2.0", stroke: red)

  cetz.draw.content("r-1.label", $r_1$)
  cetz.draw.content("r-2.label", $r_2$)

  cetz.draw.content((1.2, -0.7), $~~>$)

  cetz.draw.circle((2.5, 0), radius: 0.5, stroke: (dash: "dashed"))
  cetz.draw.circle((2.5, -1.5), radius: 0.5, stroke: (dash: "dashed"))

  wire((2.5, -0.5, -90deg), (2.5, -1, -90deg))

  cetz.draw.content((2.5, 0), $r_1$)
  cetz.draw.content((2.5, -1.5), $r_2$)

  // hidden so the widths of the diagrams are the same
  cetz.draw.content((-1.5, -0.7), hide($(i = j)$))

  cetz.draw.content((5.5, -0.7), $(4)$)
})

#post.canvas({
  con("i", (0, 0), angle: 180deg, show-aux: true)
  era("e", (0, -1.5))
  wire("i.0", "e.0", stroke: red)

  cetz.draw.content("i.label", $i$)

  cetz.draw.content((1.2, -0.7), $~~>$)

  era("e'-1", (2.5, -1.5))
  era("e'-2", (3.5, -1.5))

  wire("e'-1.0", (2.5, 2/3, 90deg))
  wire("e'-2.0", (3.5, 2/3, 90deg))

  // hidden so the widths of the diagrams are the same
  cetz.draw.content((-1.5, -0.7), hide($(i = j)$))

  cetz.draw.content((5.5, -0.7), $(5)$)
})

#post.canvas({
  ref("r", (0, 0), angle: 180deg)
  era("e", (0, -1.5))
  wire("r.0", "e.0", stroke: red)

  cetz.draw.content("r.label", $r$)

  cetz.draw.content((1.2, -0.7), $~~>$)

  // hidden so the widths of the diagrams are the same
  cetz.draw.content((-1.5, -0.7), hide($(i = j)$))

  cetz.draw.content((5.5, -0.7), $(6)$)
})

#post.canvas(caption: [$k$-SIC rewrite rules], {
  era("e1", (0, 0), angle: 180deg)
  era("e2", (0, -1.5))
  wire("e1.0", "e2.0", stroke: red)

  cetz.draw.content((1.2, -0.7), $~~>$)

  // hidden so the widths of the diagrams are the same
  cetz.draw.content((-1.5, -0.7), hide($(i = j)$))

  cetz.draw.content((5.5, -0.7), $(7)$)
})

Some things to note:
- The dashed circles in rules (3) and (4) represent replacing a reference node $r in cal(R)$ with the net it refers to.
- Rule (3) can be optimized by tracking whether a constructor node of label $i$ exists in the definition of $r$. If not,
  one can instead annihilate the $i$ node and duplicate the reference node $r$, similar to rule (5). This is commonly
  known as the _DUP-REF optimization_.
- In a interaction systems with effects, rule (6) may not be correct as there may be effects in the expansion of $r$
  when erasing it.

= Infinite Nets

Recursive -- or mutually recursive -- use of the new reference node allows for the construction of infinite nets. For
example:

#post.canvas(caption: "A lazy infinite net", {
  cetz.draw.content((0, 0), $"foo" :=$)

  con("l", (2, 0))
  era("e", (1, -1))
  ref("r", (3, -1.2))

  wire("l.0", (0.7, 0, 180deg))
  wire("l.1", "e.0")
  wire("r.0", "l.2")

  cetz.draw.content("r.label", $"foo"$)
})

is equivalent to the infinite net:

#post.canvas(caption: "An expanded infinite net", {
  cetz.draw.content((0, 0), $"foo" :=$)

  for i in range(0, 3) {
    let l = "l-" + str(i)
    let e = "e-" + str(i)

    con(l, (2 + i, 0 - 1.5 * i))
    era(e, (1 + i, -1 - 1.5 * i))

    wire(l + ".1", e + ".0")

    if i > 0 {
      wire(l + ".0", "l-" + str(i - 1) + ".2")
    }
  }

  wire("l-0.0", (0.7, 0, 180deg))

  wire("l-2.2", (5, -4, -90deg))

  cetz.draw.content((5, -4.1), $dots$)
})

This is very similar to infinite lists in Haskell, which are possible due to Haskell's laziness.  This reference
node is a way to introduce laziness even in a strict context, as references are only expanded when interacted with.

= Strict Evaluation

- Explain the strict evaluation algorithm with an example pseudocode implementation, and how it can be parallelized.
- Explain how non-terminating discarded components will cause the entire program to be non-terminating.
  - Lead into laziness: how can we determine which redexes are required to normalize the root?

= Lazy Evaluation

- Determining Necessary Interactions through Graph Traversal
- Parallelization is non-trivial
- Garbage collection is non-trivial as you need to check for connectedness

= Non-Termination

- Semantics around non-terminating nets?
- What happens if a disconnected component is non-terminating?
- Haskell has no issue with non-terminating erasure.
- Consequences of GC on laziness?

- strict alg: perform every interaction even if it doesn't not contribute to the eventually normalized result.
- lazy alg: perform interactions only found during graph traversal which are guaranteed to affect final result.
