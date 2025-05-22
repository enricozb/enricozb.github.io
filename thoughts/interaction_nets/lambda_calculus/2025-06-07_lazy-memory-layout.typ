#import "../../../typst/post.typ"
#import "../../../typst/inets.typ"
#import "@preview/cetz:0.3.4"

#import cetz.draw: *

#show: content => post.post(
  title: "Lazy Normalization - Memory Layout",
  date: "2025-06-07",
  content
)

#post.note[
  After writing the post on #link("2025-05-18_lazy-strict-eval.html")[lazy normalization], I thought I understood enough
  to implement a lazy normalizer. This proved to be false. Using memory efficiently to represent k-SIC interaction nets
  is not that simple.
]

#let (era, con, dup) = inets.with-kinds(
  era: inets.nilary-node,
  con: inets.stroked-node,
  dup: inets.filled-node,
)

#let wire = inets.wire.with(polarize: true)

= Overview

I'm going to explain a potential memory layout for lazy normalization and detail the graph traversal using this layout.
Then I'll describe the memory transformations that happen for each interaction.

= Memory Layout

- Heap contains positive ports.
- A memory address pointing to the heap is like the positive end of a wire.
- A value on the heap is the negative end of a wire.
- Reversing the arrows shows the direction of pointers.

= Interactions

#let memory(..addresses) = $
  #for (addr, ..blocks) in addresses.pos() {
    $
      #addr &: #for block in blocks {
        [`[` $#block$ `]` ]
      } \
    $
  }
$

== App - Null

#post.canvas({
  con("app", (0, 0), show-aux: true, polarities: (-1, -1, +1))
  era("nul", (2, 0))
  wire("nul.0", "app.0")

  content((-0.3, -1.2), `arg`)
  content((+0.3, -1.15), $alpha$)

  content((1, -3), memory(
    ($alpha$, [`App` $x$]),
    ($x$,  `Nul`, `arg`),
  ))

  translate((6, 0))

  content((-2, -2), $~~>$)

  era("nul", (0, -0.4), show-main: true, angle: -180deg, polarities: (-1,))
  era("nul", (1, -0.4), show-main: true, angle: -180deg, polarities: (+1,))

  content((0, -1.2), `arg`)
  content((1, -1.15), $alpha$)

  content((1, -3), memory(
    ($alpha$, `Nul`),
    ($x$, `FREE`, `arg`),
  ))

  circle((0, -0.4), radius: 0.5, stroke: (paint: red, dash: "dashed"))
  content((-1, 0.5), text(red, [missing the erasure of `arg`]), anchor: "west")
})

Problems:
- This is missing a way to clear the memory that is held onto by `arg`.
- Nothing points to `arg` anymore, it's a memory leak.
  - Maybe we need to store a set of positive ports that are "to be erased"?

== Dup - Nul

#post.canvas({
  dup("dup", (0, 0), show-aux: true, polarities: (-1, +1, +1))
  era("nul", (2, 0))
  wire("nul.0", "dup.0")

  content((-0.3, -1.15), $delta_1$)
  content((+0.3, -1.15), $delta_2$)

  content((1, -3), memory(
    ($delta_1$, [`Dup` $x$]),
    ($delta_2$, [`Dup` $x$]),
    ($x$, `Nul`, [`.` $delta_1 xor delta_2$]),
  ))

  translate((6, 0))

  content((-2, -2), $~~>$)

  era("nul", (0, -0.4), show-main: true, angle: -180deg, polarities: (+1,))
  era("nul", (1, -0.4), show-main: true, angle: -180deg, polarities: (+1,))

  content((0, -1.15), $delta_1$)
  content((1, -1.15), $delta_2$)

  content((1, -3), memory(
    ($delta_1$, `Nul`),
    ($delta_2$, `Nul`),
    ($x$, `FREE`, `FREE`),
  ))
})

Problems:
- A dup node cannot be moved. If it is moved, you'll need to update its second port which holds an XOR ptr to go
  between the two ports.

== App - Lam

#post.canvas({
  con("app", (0, 0), show-aux: true, polarities: (-1, -1, +1))
  con("lam", (2, 0), show-aux: true, polarities: (+1, +1, -1))
  wire("lam.0", "app.0")

  content((-0.3, -1.2), `arg`)
  content((+0.3, -1.15), $alpha$)

  content((+1.7, -1.15), $z$)
  content((+2.3, -1.2), `bod`)

  content((1, -3), memory(
    ($alpha$, [`App` $x$]),
    ($x$, [`Lam` $y$], `arg`),
    ($y$, [`bod`]),
    ($z$, [`Var` $x$]),
  ))

  translate((6, 0))
  content((-2, -2), $~~>$)

  wire((-0.3, -0.75, +86deg), (0.75, 0), (+1.7, -0.85, -90deg), polarize: (0.001, 1))
  wire((+2.3, -0.75, +90deg), (1.25, 0, 180deg), (+0.3, -0.85, -86deg), polarize: (0.001, 1))

  content((-0.3, -1.2), `arg`)
  content((+0.3, -1.15), $alpha$)

  content((+1.7, -1.15), $z$)
  content((+2.3, -1.2), `bod`)

  content((1, -3), memory(
    ($alpha$, [`bod`]),
    ($x$, `arg`, `FREE`),
    ($y$, `FREE`),
    ($z$, [`Var` $x$]),
  ))
})

Problems:
  - Creates an indirection through `Var`.

== Dup - Sup $thick (i = j)$

#post.canvas({
  dup("dup", (0, 0), show-aux: true, polarities: (-1, +1, +1))
  dup("sup", (2, 0), show-aux: true, polarities: (+1, -1, -1))
  wire("sup.0", "dup.0")

  content((-0.3, -1.15), $delta_1$)
  content((+0.3, -1.15), $delta_2$)

  content((+1.7, -1.15), `a`)
  content((+2.3, -1.15), `b`)

  content((1, -3), memory(
    ($delta_1$, [`Dup` $x$]),
    ($delta_2$, [`Dup` $x$]),
    ($x$, [`Sup` $y$], [`.` $delta_1 xor delta_2$]),
    ($y$, `a`, `b`),
  ))

  translate((6, 0))
  content((-2, -2), $~~>$)

  wire((+1.7, -0.75, +90deg), (0.75, 0, 180deg), (-0.3, -0.85, -86deg), polarize: (0.001, 1))
  wire((+2.3, -0.75, +90deg), (1.25, 0, 180deg), (+0.3, -0.85, -86deg), polarize: (0.001, 1))

  content((-0.3, -1.2), $delta_1$)
  content((+0.3, -1.15), $?$)

  content((+1.7, -1.15), `a`)
  content((+2.3, -1.15), `b`)

  content((1, -3), memory(
    ($delta_1$, `a`),
    ($delta_2$, `b`),
    ($x$, `FREE`, `FREE`),
    ($y$, `FREE`, `FREE`),
  ))
})

== Dup - Lam

#post.canvas({
  dup("dup", (0, 0), show-aux: true, polarities: (-1, +1, +1))
  con("lam", (2, 0), show-aux: true, polarities: (+1, +1, -1))
  wire("lam.0", "dup.0")

  content((-0.3, -1.15), $delta_1$)
  content((+0.3, -1.15), $delta_2$)

  content((+1.7, -1.15), $?$)
  content((+2.3, -1.18), `bod`)

  content((1, -2), memory(
    ($delta_1$, [`Dup` $x$]),
    ($delta_2$, [`Dup` $x$]),
    ($x$, [`Lam` $y$], [`.` $delta_1 xor delta_2$]),
    ($y$, `bod`),
    ($?$, [`Var` $x$]),
  ), anchor: "north")

  translate((6, 0))
  content((-2, -2), $~~>$)

  content((-0.3, -1), $delta_1$)
  content((+0.3, -1), $delta_2$)

  con("lam2", (1.5, +1.2), angle: 90deg)
  con("lam1", (1.5, -0.2), angle: 90deg)

  wire("lam2.0", (-0.3, -0.7, -90deg), polarize: 1)
  wire("lam1.0", (+0.3, -0.7, -90deg), polarize: 1)

  dup("dup", (3.5, +1.2), angle: -90deg)
  dup("sup", (3.5, -0.2), angle: -90deg)

  wire("lam1.1", "sup.2")
  wire("dup.2", "lam1.2", polarize: 0.8)

  wire("lam2.1", "sup.1", polarize: 0.25)
  wire("dup.1", "lam2.2")

  content((5-0.3, -1), $?$)
  content((5+0.3, -1), `bod`)

  wire("sup.0", (5-0.3, -0.7, -90deg), polarize: 1)
  wire((5+0.3, -0.6, 105deg), "dup.0", polarize: 0.0001)

  content((2.5, -2), memory(
    ($delta_1$, [`Lam` $y$]),
    ($delta_2$, [`Lam` $x'$]),
    ($x$, [`Sup` $hat(w)$], [`Dup` $hat(z)$]),
    ($y$, [`Dup` $hat(z)$]),
    ($hat(w)$, [`Var` $delta_1$], [`Var` $delta_2$]),
    ($hat(z)$, `bod`, [`.` $x' xor y$]),
    ($?$, [`Var` $x$]),
  ), anchor: "north")
})

Notes:
- allocates two new double-wide nodes, which is what we expect.
- frees nothing, so memory is maximally reused.
