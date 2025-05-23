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
  is not that simple. This blog post is a detailed explanation on a possibly efficient memory layout for polarized
  k-SIC normalization.
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

= Problems
- No garbage collection, unclear how to safely erase things.
- It is impossible to tell which dup node port we are entering through.

= Memory Layout

- The heap stores negative ports.
  - Entries on the heap are double-words (2 × 64 bits)
  - Addresses are 8-byte aligned, so they can point to an upper or lower word within an entry on the heap.
  - The exception to this is the second half of a Dup node, which stores an XOR of the pointers to its aux ports.
- Reversing the arrows shows the direction of pointers.
  - A pointer into the heap is the end of a polarized wire.
  - A value on the heap is the negative start a polarized wire.

= Interactions

#let memory(..addresses) = $
  #for (addr, ..blocks) in addresses.pos() {
    $
      #addr &: #for block in blocks {
        [ #text(size: 14pt, `[`) $#block$ #text(size: 14pt, `]`) ]
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
  content((+0.3, -1.15), $a$)

  content((1, -3), memory(
    ($a$, [`App` $x$]),
    ($x$,  `Nul`, `arg`),
  ))

  translate((6, 0))

  content((-2, -2), $~~>$)

  era("nul", (0, -0.4), show-main: true, angle: -180deg, polarities: (-1,))
  era("nul", (1, -0.4), show-main: true, angle: -180deg, polarities: (+1,))

  content((0, -1.2), `arg`)
  content((1, -1.15), $a$)

  content((1, -3), memory(
    ($a$, `Nul`),
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

  content((-0.3, -1.15), $d_1$)
  content((+0.3, -1.15), $d_2$)

  content((1, -3), memory(
    ($d_1$, [`Dup1` $x$]),
    ($d_2$, [`Dup2` $x$]),
    ($x$, `Nul`, [`.` $d_1 xor d_2$]),
  ))

  translate((6, 0))

  content((-2, -2), $~~>$)

  era("nul", (0, -0.4), show-main: true, angle: -180deg, polarities: (+1,))
  era("nul", (1, -0.4), show-main: true, angle: -180deg, polarities: (+1,))

  content((0, -1.15), $d_1$)
  content((1, -1.15), $d_2$)

  content((1, -3), memory(
    ($d_1$, `Nul`),
    ($d_2$, `Nul`),
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
  content((+0.3, -1.15), $a$)

  content((+1.7, -1.15), $z$)
  content((+2.3, -1.2), `bod`)

  content((1, -3), memory(
    ($a$, [`App` $x$]),
    ($x$, [`Lam` $y$], `arg`),
    ($y$, [`.` $z$], [`bod`]),
    ($z$, [`Var` $x$]),
  ))

  translate((6, 0))
  content((-2, -2), $~~>$)

  wire((-0.3, -0.75, +86deg), (0.75, 0), (+1.7, -0.85, -90deg), polarize: (0.001, 1))
  wire((+2.3, -0.75, +90deg), (1.25, 0, 180deg), (+0.3, -0.85, -86deg), polarize: (0.001, 1))

  content((-0.3, -1.2), `arg`)
  content((+0.3, -1.15), $a$)

  content((+1.7, -1.15), $z$)
  content((+2.3, -1.2), `bod`)

  content((1, -3), memory(
    ($a$, [`bod`]),
    ($x$, `FREE`, `FREE`),
    ($y$, `FREE`, `FREE`),
    ($z$, `arg`),
  ))
})

== Dup - Sup $thick (i = j)$

#post.canvas({
  dup("dup", (0, 0), show-aux: true, polarities: (-1, +1, +1))
  dup("sup", (2, 0), show-aux: true, polarities: (+1, -1, -1))
  wire("sup.0", "dup.0")

  content((-0.3, -1.15), $d_1$)
  content((+0.3, -1.15), $d_2$)

  content((+1.7, -1.15), `a`)
  content((+2.3, -1.15), `b`)

  content((1, -3), memory(
    ($d_1$, [`Dup` $x$]),
    ($d_2$, [`Dup` $x$]),
    ($x$, [`Sup` $y$], [`.` $d_1 xor d_2$]),
    ($y$, `a`, `b`),
  ))

  translate((6, 0))
  content((-2, -2), $~~>$)

  wire((+1.7, -0.75, +90deg), (0.75, 0, 180deg), (-0.3, -0.85, -86deg), polarize: (0.001, 1))
  wire((+2.3, -0.75, +90deg), (1.25, 0, 180deg), (+0.3, -0.85, -86deg), polarize: (0.001, 1))

  content((-0.3, -1.2), $d_1$)
  content((+0.3, -1.2), $d_2$)

  content((+1.7, -1.15), `a`)
  content((+2.3, -1.15), `b`)

  content((1, -3), memory(
    ($d_1$, `a`),
    ($d_2$, `b`),
    ($x$, `FREE`, `FREE`),
    ($y$, `FREE`, `FREE`),
  ))
})

== Dup - Sup $thick (i != j)$

#post.canvas({
  dup("dup", (0, 0), show-aux: true, polarities: (-1, +1, +1))
  dup("sup", (2, 0), show-aux: true, polarities: (+1, -1, -1))
  wire("sup.0", "dup.0")

  content("dup.label", text(white, $i$))
  content("sup.label", text(white, $j$))

  content((-0.3, -1.15), $d_1$)
  content((+0.3, -1.15), $d_2$)

  content((+1.7, -1.15), `a`)
  content((+2.3, -1.15), `b`)

  content((1, -2), memory(
    ($d_1$, $#`Dup1`_i thick x$),
    ($d_2$, $#`Dup2`_i thick x$),
    ($x$, $#`Sup`_j thick y$, [`.` $d_1 xor d_2$]),
    ($y$, `a`, `b`),
  ), anchor: "north")

  translate((6, 0))
  content((-2, -2), $~~>$)

  content((-0.3, -1), $d_1$)
  content((+0.3, -1), $d_2$)

  dup("sup1", (1.5, +1.2), angle: 90deg)
  dup("sup2", (1.5, -0.2), angle: 90deg)

  content("sup1.label", text(white, $j$))
  content("sup2.label", text(white, $j$))

  wire("sup1.0", (-0.3, -0.7, -90deg), polarize: 1)
  wire("sup2.0", (+0.3, -0.7, -90deg), polarize: 1)

  dup("dup2", (3.5, +1.2), angle: -90deg)
  dup("dup1", (3.5, -0.2), angle: -90deg)

  content("dup2.label", text(white, $i$))
  content("dup1.label", text(white, $i$))

  wire("dup1.2", "sup2.1")
  wire("dup2.2", "sup2.2", polarize: 0.8)

  wire("dup1.1", "sup1.1", polarize: 0.25)
  wire("dup2.1", "sup1.2")

  content((5-0.3, -1), `a`)
  content((5+0.3, -1), `b`)

  wire((5-0.3, -0.7, +90deg), "dup1.0", polarize: 0)
  wire((5+0.3, -0.7, +90deg), "dup2.0", polarize: 0)

  content((2.5, -2), memory(
    ($d_1$, $#`Sup`_j thick x$),
    ($d_2$, $#`Sup`_j thick y$),
    ($x$, $#`Dup1`_i thick w$, $#`Dup1`_i thick q$),
    ($y$, $#`Dup2`_i thick w$, $#`Dup2`_i thick q$),
    ($w$, `a`, [`.` $x xor y$]),
    ($q$, `b`, [`.` $x' xor y'$]),
  ), anchor: "north")
})

Notes:
- allocates two new double-wide nodes, which is what we expect.
- frees nothing, so memory is maximally reused.

== Dup - Lam

#post.canvas({
  dup("dup", (0, 0), show-aux: true, polarities: (-1, +1, +1))
  con("lam", (2, 0), show-aux: true, polarities: (+1, +1, -1))
  wire("lam.0", "dup.0")

  content((-0.3, -1.15), $d_1$)
  content((+0.3, -1.15), $d_2$)

  content((+1.7, -1.15), $z$)
  content((+2.3, -1.15), `bod`)

  content((1, -2), memory(
    ($d_1$, [`Dup1` $x$]),
    ($d_2$, [`Dup2` $x$]),
    ($x$, [`Lam` $y$], [`.` $d_1 xor d_2$]),
    ($y$, [`.` $z$], `bod`),
    ($z$, [`Var` $x$]),
  ), anchor: "north")

  translate((6, 0))
  content((-2, -2), $~~>$)

  content((-0.3, -1), $d_1$)
  content((+0.3, -1), $d_2$)

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

  content((5-0.3, -1), $z$)
  content((5+0.3, -1), `bod`)

  wire("sup.0", (5-0.3, -0.7, -90deg), polarize: 1)
  wire((5+0.3, -0.6, 90deg), "dup.0", polarize: 0)

  content((2.5, -2), memory(
    ($d_1$, [`Lam` $x$]),
    ($d_2$, [`Lam` $y$]),
    ($x$, [`.` $w$], [`Dup1` $q$]),
    ($y$, [`.` $w'$], [`Dup2` $q$]),
    ($z$, [`Sup` $w$]),
    ($w$, [`Var` $x$], [`Var` $y$]),
    ($q$, `bod`, [`.` $x' xor y'$]),
  ), anchor: "north")
})

Notes:
- allocates two new double-wide nodes, which is what we expect.
- frees nothing, so memory is maximally reused.

== App - Sup

#post.canvas({
  con("app", (0, 0), show-aux: true, polarities: (-1, -1, +1))
  dup("sup", (2, 0), show-aux: true, polarities: (+1, -1, -1))
  wire("sup.0", "app.0")

  content((-0.3, -1.15), `arg`)
  content((+0.3, -1.10), $a$)

  content((+1.7, -1.15), `a`)
  content((+2.3, -1.15), `b`)

  content((1, -2), memory(
    ($a$, [`App` $x$]),
    ($x$, [`Sup` $s$], `arg`),
    ($s$, `a`, `b`),
  ), anchor: "north")

  translate((6, 0))
  content((-2, -2), $~~>$)

  content((-0.3, -1), `arg`)
  content((+0.3, -0.95), $a$)

  dup("dup", (1.5, +1.2), angle: 90deg)
  dup("sup", (1.5, -0.2), angle: 90deg)

  wire((-0.3, -0.6, 90deg), "dup.0",  polarize: 0)
  wire("sup.0", (+0.3, -0.7, -90deg), polarize: 1)

  con("app1", (3.5, +1.2), angle: -90deg)
  con("app2", (3.5, -0.2), angle: -90deg)

  wire("dup.2", "app1.1")
  wire("dup.1", "app2.1", polarize: 0.25)
  wire("app1.2", "sup.2", polarize: 0.8)
  wire("app2.2", "sup.1")

  content((5-0.3, -1), `a`)
  content((5+0.3, -1), `b`)

  wire((5-0.3, -0.6, 90deg), "app2.0", polarize: 0)
  wire((5+0.3, -0.6, 90deg), "app1.0", polarize: 0)

  content((2.5, -2), memory(
    ($a$, [`Sup` $s$]),
    ($x$, `arg`, [`.` $a_1 xor a_2$]),
    ($s$, [`App` $a_1$], [`App` $a_2$]),
    ($a_1$, `a`, [`Dup1` $x$]),
    ($a_2$, `b`, [`Dup2` $x$]),
  ), anchor: "north")
})

Notes:
- alocates two new double-wide nodes, which is what we expect.
- frees nothing, so memory is maximally reused.
