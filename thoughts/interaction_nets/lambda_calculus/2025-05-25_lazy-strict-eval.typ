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

  This post and the others would not exist without the always-fruitful conversations with #link("https://t6.dev/")[T6].
]

#let (era, con, dup, ref, tree) = inets.with-kinds(
  era: inets.nilary-node,
  con: inets.stroked-node,
  dup: inets.filled-node,
  ref: inets.reference-node,
  tree: inets.double-stroked-node,
)

#let wire = inets.wire

= Overview

There are currently two main algorithms for normalizing interaction nets: lazy evaluation and strict evaluation. We'll
see that these two algorithms are somewhat at odds with each other. Specifically, strict evaluation is highly
parallelizable and has garbage collection for free, while lazy evaluation can normalize a larger class of terms. In
order to understand this difference, we'll have to introduce a new family#footnote[To be more accurate, this
family of interaction systems is parametrized by the number of binary nodes $k$ and the set of named nets $cal(R)$.
Additionally, the presented rewrite rules are also a family or schema of rewrite rules. There are actually
$thick 2^(k+|cal(R)|+1)$ possible kinds of interactions.] of interaction systems: $k$-SIC with reference nodes.

= $k$-SIC + References

$k$-SIC is natural extension of 2-SIC, where we have $k$ different kinds (also known as _labels_) of binary nodes
that annihilate when they are of the same kind, and commute when they are of different kinds. Additionally, we're
going to add a new kind of node known as a _reference node_. This is a deferred reference to a named net, which
will be copied when interacted with. Named nets must have a free wire#footnote[Much like how our translations of
lambda calculus terms would refer to nets through a free wire.]. The set of names $cal(R)$ is fixed.

For the remainder of the post, we'll refer to this interaction system as simply $k$-SIC without explicitly mentioning
the addition of reference (and eraser) nodes every time.

The kinds of nodes now looks like:

#post.canvas(caption: [$k$-SIC nodes], {
  era("e", (0, 0), show-ports: true)
  con("c", (2, 0), show-ports: true)
  ref("r", (4, 0), show-ports: true)

  cetz.draw.content("c.label", $i$)
  cetz.draw.content("r.label", $r$)

  cetz.draw.content((2, -1.5), $i in {1, dots, k}$)

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
  known as the _DUP-REF optimization_, and prevents expanding a reference node that might be erased.
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

This is very similar to infinite lists in Haskell, which are possible due to Haskell's laziness. Now, just like
in lambda calculus, one does not need to add an additional construct like references in order to have recursion
or non-termination. What we will see later on in this post is that this reference node defers computation, introducing
a kind of laziness even in strict settings.

The difficulty in dealing with non-terminating nets is that strong confluence#footnote[See the strong confluence
section in the post on #link("2025-04-25_normalization.html")[normalization].] guarantees if any reduction path
is of infinite length, then all reduction paths are.

= Strict Evaluation

The rewrite rules of interaction nets as described in previous posts and this one emulate a strict evaluation
strategy. By strict we mean that every part of the net is normalized, _even if it is disconnected from the root
free wire_. This implies that if any portion of the net does not have a normal form -- because of non-termination
-- then the entire net does not have a normal form. A similar situation exists in lambda calculus. For example,
consider the following lambda calculus program:

$
& "let" id := lambda x.x "in" \
& "let" Omega := (lambda x. x x) (lambda x. x x) "in" \
& ("K" id Omega)
$

Using a #link("https://en.wikipedia.org/wiki/Evaluation_strategy#Non-strict_evaluation")[normal order evaluation]
strategy, it should normalize to $id$, as $K$ simply discards its second argument. Using a strict evaluation strategy,
however, would result in non-termination as the argument $Omega$ has no normal form.

When encoding $thick ("K" id Omega) thick$ into $k$-SIC#footnote[Two distinct labels are used in this encoding, one
for duplication and one for the application/abstraction nodes. Additionally, the actual encoding of $Omega$ is slightly
longer. The encoding in the diagram uses a duplication to share the term $lambda x. x x$ just to minimize the figure,
but is equivalent.], we get the following:

#post.canvas(caption: "A strictly diverging net", {
  let wire = wire.with(polarize: 0.67)

  cetz.draw.content((0, 0), $id := $, anchor: "east")

  con("c", (1.5, 0), angle: 90deg)
  wire("c.0", (0.5, 0, 180deg), polarize: 1)
  wire("c.1", "c.2")

  cetz.draw.translate((0, -2))

  cetz.draw.content((0, 0), $"K" := $, anchor: "east")

  con("l1", (1.5, 0), angle: 90deg)
  con("l2", (3, 0.5), angle: 90deg)
  era("e", (4, 0), angle: 90deg)

  wire("l1.0", (0.5, 0, 180deg), polarize: 1)
  wire("l2.0", "l1.2")
  wire("l2.1", "e.0")

  wire("l1.1", (4.5, 0, 90deg), "l2.2")

  cetz.draw.content((-1.5, -0.5), $cal(R) = stretch(brace.l, size: #18em)$, anchor: "east")

  cetz.draw.translate((0, -2))

  cetz.draw.content((0, 0), $Omega := $, anchor: "east")

  dup("d", (3, 0), angle: -90deg)
  con("a", (1.5, -0.5), angle: -90deg)

  wire("d.2", "a.0")
  wire("d.1", (1, 0.5, 180deg), "a.1")
  wire("a.2", (0.2, 0, 180deg), polarize: 1)

  con("l", (4.5, 0), angle: 90deg)
  wire("l.0", "d.0")

  con("a", (7.5, 0), angle: 90deg)
  dup("d", (6, -1), angle: 90deg)

  wire("l.1", "d.0")
  wire("d.1", (8, -1, 30deg), "a.1")
  wire("d.2", "a.0")
  wire("a.2", (8, 1, 180deg), "l.2")

  cetz.draw.translate((3, -4))

  con("a1", (0, 0), angle: 90deg)
  con("a2", (1.5, 1), angle: 90deg)

  ref("k", (-1.5, 0), angle: -90deg)
  ref("id", (1.5, -1), angle: 90deg)
  ref("omega", (3, 0.5), angle: 90deg)

  wire("k.0", "a1.0")
  wire("id.0", "a1.1")
  wire("a1.2", "a2.0")
  wire("omega.0", "a2.1")
  wire("a2.2", (2, 2, 180deg), (-2.5, 1, 180deg), polarize: 1)

  cetz.draw.content((-4, 1), $[| ("K" id Omega) |] = $)

  cetz.draw.content("k.label", "K")
  cetz.draw.content("id.label", "id")
  cetz.draw.content("omega.label", $Omega$)
})

If you step through the reduction, you should reach the following intermediate net within a few rewrites:

#post.canvas(caption: [Normalization of $thick ("K" id Omega) thick$ with reference nodes], label: "intermediate-net", {
  let wire = wire.with(polarize: 0.67)

  con("l", (-1, 0), angle: -90deg)
  con("a", (1, 0), angle: 90deg)
  era("e", (-2.5, 0.5), angle: -90deg)
  ref("id", (-2.5, -0.5), angle: -90deg)
  ref("omega", (2.5, -0.5), angle: 90deg)

  wire("l.0", "a.0", polarize: 0.55)
  wire("l.1", "e.0")
  wire("id.0", "l.2")
  wire("omega.0", "a.1")
  wire("a.2", (2.5, 0.5), polarize: 1)

  cetz.draw.content("id.label", "id")
  cetz.draw.content("omega.label", $Omega$)

  cetz.draw.content((0, -1.2), $~~>$, angle: -90deg)

  cetz.draw.translate((0, -2.5))

  era("e", (-2.5, 0.5), angle: -90deg)
  ref("id", (-2.5, -0.5), angle: -90deg)
  ref("omega", (2.5, -0.5), angle: 90deg)

  wire("omega.0", "e.0")
  wire("id.0", (2.5, 0.5), polarize: 1)

  cetz.draw.content("id.label", "id")
  cetz.draw.content("omega.label", $Omega$)

  cetz.draw.content((0, -1.2), $~~>$, angle: -90deg)

  cetz.draw.translate((0, -2.5))

  ref("id", (-1, 0), angle: -90deg)
  wire("id.0", (1, 0), polarize: 1)

  cetz.draw.content("id.label", $id$)
})

Clearly, the reference to $Omega$ is erased, and by rewrite rule (6), the reference is not expanded. The result is then
$id$ as expected.

Without reference nodes however, the presence of $Omega$ anywhere in the net will require that it is normalized,
as it has an active pair. The intermediate net in @intermediate-net would instead look like this:

#post.canvas(caption: [$thick ("K" id Omega)thick $ without reference nodes], {
  let wire = wire.with(polarize: 0.67)

  era("e", (0.5, -1), angle: -90deg)
  dup("d", (3, 0), angle: -90deg)
  con("a", (1.5, -0.5), angle: -90deg)

  wire("d.2", "a.0")
  wire("d.1", (1, 0.5, 180deg), "a.1")
  wire("a.2", "e.0")

  con("l", (4.5, 0), angle: 90deg)
  wire("l.0", "d.0")

  con("a", (7.5, 0), angle: 90deg)
  dup("d", (6, -1), angle: 90deg)

  wire("l.1", "d.0")
  wire("d.1", (8, -1, 30deg), "a.1")
  wire("d.2", "a.0")
  wire("a.2", (8, 1, 180deg), "l.2")

  ref("id", (3, -2), angle: -90deg)
  wire("id.0", (5, -2), polarize: 1)

  cetz.draw.content("id.label", $id$)
})

Notice that the net is no longer fully connected. Even though the root free wire is clearly referencing just
$id$, there are still active pairs in this net. Specifically, the erasure of $Omega$. In a strict interaction
net settings, erasing a term normalizes it first. Like in lambda calculus, attempting to normalize $Omega$ in
this $k$-SIC encoding will never terminate. Thus, in a strict setting, normalization of $[|("K" id Omega)|]$
using $k$-SIC does not terminate.

_Reference nodes are therefore a way to introduce laziness into an otherwise strict context_, allowing one to
erase infinite terms by defering their expansion.

== Strict Evaluation Algorithm

An implementation of a strict evaluation algorithm for interaction combinators / $k$-SIC requires two main components,
a buffer of nodes, and a collection of redexes. The buffer of nodes can be a self-referential array where some elements
hold pointers to others in the array. These pointers are essentially the wires, and the nodes in the buffer contain
information about the kind of node. The redexes can just be pairs of pointers to nodes.

The algorithm is then to continuously pop from the collection of redexes and perform the appropriate interaction
depending on the kind of nodes in the redex. When linking wires together, new redexes may be formed. These should be
re-added to the collection of redexes.

This algorithm is easy to parallelize. Spawn as many threads as you wish, and have them continuously pop from the
redexes. One just needs to ensure that redexes are grabbed atomically. Since a node can only be part of at most
a single redex, there isn't too much difficulty with thread-safety, as obtaining a redex implies ownership of the
two nodes in that redex.

Once the collection of redexes is empty, the net is normalized.

= Lazy Evaluation

#let phase-1 = blue.transparentize(30%) + 2pt
#let phase-2 = green.transparentize(30%) + 2pt

While references allow for a form of laziness, they require explicitly marking a laziness boundary. Another way
to handle the erasure of infinite nets is by not reducing any part of the net that is no longer connected to the
root. This requires some way of knowing whether a redex actually contributes to the final term connected to the
root wire.

Note that once a net is no longer to the root wire, it can never be reconnected, as disconnected nets cannot interact.

How can we determine which redexes are required in order to normalize the net eventually connected to the root wire? A
first intuition would be to walk the net starting at the root, when we see a redex we reduce it, and then restart the
walk.

Let's imagine some hypothetical net:

#post.canvas(caption: "A hypothetical net", {
  con("1", (0, 0), show-main: true, polarities: (1,))
  con("2", (-1, -1.5), show-aux: true)
  con("3", (+1, -1.5), show-aux: true)

  wire("1.1", "2.0")
  wire("1.2", "3.0")

  cetz.draw.content((-1.3, -2.5), $dots$)
  cetz.draw.content((-0.7, -2.5), $dots$)
  cetz.draw.content((+0.7, -2.5), $dots$)
  cetz.draw.content((+1.3, -2.5), $dots$)
})

A portion of a net like this is known as a _tree_, where aux ports always connect to principal ports. Let's call this
tree at the head of the root term the _initial tree_, and represent it as an outlined node. Node that the tree does
not have to be balanced.

#post.canvas(caption: "An initial tree", {
  tree("t", (0, 0), show-ports: true, polarities: (1,))
  cetz.draw.content((0, -0.5), $dots$)
})

What's interesting about these initial trees is that, no matter what is downstream of the tree, _they will always
be present in the normalized term_. In some sense, this initial portion of the term is already normalized. This is
because these nodes can only be removed/rewritten if their main ports were wired to another main port.

Thus, _when starting a net traversal at the root, we enter through main ports and exit through auxiliary ports_. This
is known as _phase 1_ of the lazy evaluation algorithm.

While walking the net, if we ever enter a node through one of its auxiliary ports, we may no longer in the
initial tree. However, we may be going back up the tree instead of going down. For example,

#post.canvas(caption: "A walk reentering the initial tree", {
  cetz.draw.scale(1.5)

  tree("t", (0, 0), show-main: true, polarities: (1,))

  wire("t.1", "t.2")

  cetz.draw.content((0, -0.5), $dots$)

  wire(
    (0, 1, -90deg),
    (0, 0.1, -90deg),
    (0.4, -0.5, -90deg),
    (-0.4, -0.5, 90deg),
    stroke: phase-1,
    polarize: (0.00001, 1),
    layer: 1
  )
})

Thus, _during a net traversal, when entering through auxiliary ports, we exit through main ports_. Once we first enter
through an auxiliary port, we are now in _phase 2_.

During phase 2, if we ever enter a main port, we are in a redex:

#post.canvas(caption: "Example walk encountering a redex", label: "example-walk", {
  cetz.draw.scale(1.5)

  tree("t", (0, 0), show-main: true, polarities: (1,))
  cetz.draw.content((0, -0.5), $dots$)

  con("1", (2.5, -1.5), angle: 90deg)
  con("2", (1, -2), angle: 90deg)
  con("3", (-1, -2), angle: -90deg)

  wire("t.2", (2.5, -0.6), "1.2")
  wire("2.2", "1.0")
  wire("3.0", "2.0")
  wire("3.1", (-1, -1), "t.1")

  wire(
    (0, 1, -90deg),
    (0, 0, -90deg),
    (0.4, -0.5, -90deg),
    (2.5, -0.6),
    (3, -1.2, 180deg),
    stroke: phase-1,
    polarize: (0.0001, 0.7, 1),
    layer: 1
  )

  wire(
    (2.9, -1.2, 180deg),
    (2.3, -1.5, 180deg),
    (2, -1.5, 180deg),
    (0.8, -2, 180deg),
    (0.5, -2, 180deg),
    "3.0",
    stroke: phase-2,
    polarize: (0.01, 0.45, 1),
    layer: 1
  )

  cetz.draw.line((2, 1), (2.5, 1), stroke: phase-1)
  cetz.draw.line((2, 0.5), (2.5, 0.5), stroke: phase-2)

  cetz.draw.content((2.7, 1), "Phase 1", anchor: "west")
  cetz.draw.content((2.7, 0.5), "Phase 2", anchor: "west")

  cetz.draw.circle("3.0.p", radius: 0.3, stroke: (paint: red, dash: "dashed"))
})

I'm not drawing some of the auxiliary wires in order to minimize noise in an already noisy diagram.

Once we find a redex, we can reduce it, and restart the walk from the root#footnote[There's an immediate optimization
here, where one can restart the walk from the previously exited main port, instead of restarting from the root]. If
there is no redex, the walk will eventually return to the root, assuming that the net does not contain any _vicious
circles_#footnote[Vicious circles are nonsensical terms, such as a lambda returning itself as the body. These terms
are "worse" than non-terminating terms like $Omega$ as they are "normalized" but cannot be read back. In some sense,
these terms are not well-formed.].

Since we're walking through nodes connected to the root, disconnected components will not be reduced further. This
algorithm searches for nodes to contribute to the initial tree, greedily expanding it until no further redexes
exist. Any node added to the initial tree necessarily contributed to the final normalized term, since once a node is
added to the initial tree it cannot be removed.

== Garbage Collection

One interesting practical consequence of this net traversal algorithm is that disconnected components must be garbage
collected somehow. In a strict setting, discarding a net by connecting it to an eraser will eventually reclaim all of
the memory that was used to store that net. However, if a net becomes disconnected from the root in a lazy setting,
we no longer perform interactions on it. Thus, we need some additional code / strategy to periodically detect such
components and free their memory. If we devise such a mechanism, we gain an additional benefit that the memory can
be freed without performing any interactions, but it will take some additional computation to detect disconnected nets.

== Parallelism in Lazy Evaluation

One opportunity for parallelism in the lazy evaluation algorithm is in phase 1: when entering through a main port,
_spawn two threads to continue walking through both auxiliary ports_. Detecting contention here is much more nuanced,
as two walks can end up at the same redex such as in @example-walk. It is beyond the scope of this post to discuss
potential parallel lazy algorithms, as a single-threaded one is semantically sufficient.

However, it is important to note that *the upper bound on the amount of parallelism (number of concurrent threads) is
the number of leaves in the initial tree of the final term*. This is because this algorithm can only be parallelized
during phase 1, and phase 1 the walk over the initial tree. Thus, if the final term is, say, a null eraser $*$, then
no concurrent threads were possibly spawned during reduction, no matter initial term.

This is a heavy consequence of a lazy evaluation strategy for a variety of computations. Numerical computations for
example that normalize to a single number (in some interaction system with native integers) will not benefit from
any of the parallel benefits of interaction nets.

== Semantics of Lazy Evaluation

One interesting question is: which lambda calculus evaluation strategy does the lazy
interaction net evaluation strategy correspond to? It turns out that it is something in between a
#link("https://wiki.haskell.org/index.php?title=Weak_head_normal_form")[weak head normal form] and a strict
normalization. Infinite / non-terminating terms that eventually become disconnected from the root will not result
in non-termination of the entire term. However, if the root term is in fact infinite / non-terminating, then
normalization will never complete.

_If there is a path of beta-reductions that terminates and produces a finite term, the lazy reduction algorithm will
find it_.

This is not as lazy as a lambda calculus normalization strategy that computes a weak head normal form, as WHNF
leaves body of abstractions unnormalized. However, it is lazy in a call-by-need sense in that function arguments
are normalized only when needed. Thus implying that control flow mechanisms (such as branching) do not require
any special nodes to short-circuit.

Of course, this algorithm is still Lévy/beta-optimal.

= Conclusion

We discussed the two most prominent normalization strategies for interaction nets, and discussed their individual
trade-offs. Additionally, we demonstrated that reference nodes in a strict setting are an intermediate that may
balance the benefits of both systems.
