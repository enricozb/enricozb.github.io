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

#let (era, con, dup, ref) = inets.with-kinds(
  era: inets.nilary-node,
  con: inets.stroked-node,
  dup: inets.filled-node,
  ref: inets.reference-node,
)

#let wire = inets.wire.with(polarize: true)

#let memory(..addresses) = $
  #for (addr, ..blocks) in addresses.pos() {
    $
      #addr &: #for block in blocks {
        [ #text(size: 14pt, `[`) $#block$ #text(size: 14pt, `]`) ]
      } \
    $
  }
$

= Overview

I'm going to explain a potential memory layout for lazy normalization and detail the graph traversal using this layout.
The memory layout includes both how nodes and wires are represented, and then the memory transformations that happen
for each interaction.

= Allocation

While in a sensible system the memory layout shouldn't really be tied to the allocation mechanism, the scheme I'm
detailing here will have such a coupling. So, I'll need to describe the allocator as well.

The allocator first allocates a single memory arena as large as the OS will allow. We'll refer to this region of memory
as the _heap_. The heap is aligned to the nearest 16 bytes. This is because the allocator deals with double-word
(128-bit) values.

The allocator has a simple API:

#post.code(caption: "Allocator API",
  ```rust
  /// An address to a _single_ word on the heap.
  pub struct Addr(*const u64);

  /// Returns a 16-byte aligned address.
  fn alloc_double_word(&mut self) -> Option<Addr>

  /// Expects an 8-byte aligned address.
  fn free_single_word(&mut self, addr: Addr)

  /// Expects a 16-byte aligned address.
  fn free_double_word(&mut self, addr: Addr)
  ```
)

== Memory Reuse

The allocator uses a #link("https://en.wikipedia.org/wiki/Free_list")[free list] to track free memory regions. This
attempts to maximise the reuse of memory. If a single word is freed, the allocator checks if its neighboring half is
also free. If so, the whole 128-bit value is freed. Since only double words can be allocated, a free single word will
not be reused unless its neighboring half is also free. _This fact is explicitly relied on by the memory representation
of nets. Specifically, some owned double-word values will keep one half free to represent a special form of the value_.

= In-Memory Representation of Nodes

== Ports

We will be storing polarized $k$-SIC nodes. Roughly, every 64-bit value on the heap is some negative port in a
node. There are some exceptions to this, but this is broadly the case. These 64-bit values can also be seen as the
terminal end of a polarized wire. The single-word values store information on what is on the initial end of such
a wire.

Every double-word value on the heap, except the root at index 0, describes some node. For nodes with two negative
ports, each word is one of those ports. For nodes with a single negative port, one word is that negative port and
the other is information on where the other ports are wired to.

The memory layout of thes 64-bit, single-word, values is:

#post.canvas(caption: "Memory layout of a port", {
  content((0, 0),
    ```text
    [ 16-bit label ][ 44-bit address ][ 4-bit tag ]
    ```,
    anchor: "north")

  content((1.6, -0.8), $stretch(brace.l, size: #14.5em)$, anchor: "west", angle: 90deg)

  content((1.6, -1.0), "48-bit, 16-byte aligned, user-space address", anchor:"north")
})

The lowest 4 bits are a `Tag`, and these guide how to interpret the remaining 60 bits. Here are the tags:

#post.code(caption: "Possible tags",
  ```rust
  pub enum Tag {
    /// A positive eraser.
    Nul = 1,
    /// The return port of an application node.
    App = 2,
    /// The main port of a lambda node.
    Lam = 3,
    /// The first port of a lambda node, the variable.
    Var = 4,
    /// An aux port of a duplication node.
    Dup = 5,
    /// The main port of a superposition node.
    Sup = 6,

    /// An XOR of the addresses of a dup's aux ports.
    ///
    /// This variant has two values because addresses to dup aux ports are 8-byte aligned, so only
    /// the bottom _3_ bits are 0. Thus we cover both cases where the 4th lowest bit may be 0 or 1
    /// And map them to the same variant.
    ///
    /// When creating new DupXor 64-bit values, we, of course, use 0b0000.
    DupXor = 0b0000 | 0b1000,

    /// The address of a lambda's variable.
    ///
    /// Because the label bits of this 64-bit value are unused, we can store whether this addr is
    /// the upper or lower half, like for the Sup tag. So, unlike the DupXor value, we don't need
    /// two tags, as we're not storing an 8-byte aligned address in the addr bits.
    VarAddr = 8,

    /// Reference nodes that map to a named net with a single free positive wire.
    Ref = 9,
  }
  ```
)

The first 16-bits are labels used by the duplication and superposition nodes. To be clear, the application and lambda
nodes are different polarizations of the same kind of node, then there are reference nodes, and finally there are $2^16$
dup/sup nodes.

The 45-bit address bits are actually a 48-bit user-space pointer into the heap#footnote[This representation explicitly
relies on the fact that most 64-bit processors do not use the upper 16-bits of addressing space.]. Since these pointers
are 8-byte aligned, the bottom 3 bits are all 0. Thus, we can store the `Tag` inline with these addresses. Not
all node tags use these address bits.

#post.note[
  The `Var` could instead store a `dw addr` and use its unused `label` space to store whether its parent lambda node is
  the first or second half. Then, since we store only `dw addr`s, the bottom four bits could be free, and we could
  expand the size of `Tag`.
]

Here is a summary of how each tag uses its bits:

#post.code(caption: "Tag-dependent port interpretations",
  ```text
  [       ][ dw addr ][ App     ]
  [       ][ dw addr ][ Lam     ]
  [       ][ dw addr ][ Var     ]
  [       ][         ][ Nul     ]
  [ 0 | 1 ][ dw addr ][ Dup     ]
  [ label ][ dw addr ][ Sup     ]
  [ label ][ 45 bits ][ DupXor  ]
  [ 0 | 1 ][ dw addr ][ VarAddr ]
  ```
)

The two kinds of addresses `dw` and `w` double-word-aligned and single-word-aligned, respectively. Unused portions
are typically 0.  `Ref` nodes interpret their address bits as an index into a global map of references $cal(R)$.

== Nodes

Ports which make use of their address bits expect a specific structure at that address in the heap. We will
detail each of those now. In the memory layouts that follow, we'll use code-script to represent values on the heap
(e.g. `fun` or `arg`). Math-script is used to represent memory addresses (e.g. $a$ or $x$).

When displaying these nodes, memory addresses with only a single port next to them are 8-byte aligned addresses, and
addresses with two ports are 16-byte aligned. For example, consider the diagram

#post.canvas({
  content((4, 0), memory(
    ($a$, [`App` $x$]),
    ($x$,  `fun`, `arg`),
  ))
})

Above, $a$ is 8-byte aligned while $x$ is 16-byte aligned. Lastly, an address with an apostrophe is the second
half of a 16-byte-aligned address. For example, $thick x'$ would refer to `arg` above.

Additionally, if we show a port with a tag of `.`, this implies that the tag is irrelevant or uninterpretable. The
entire 64-bit value of the port is used opaquely by the node that holds a pointer to it.

Lastly, we use subscripts to refer to the `label` portion of a port. For example, $thick #`[` #`Sup`_i thick x #`]`$
is a port with the `Sup` tag, label $i$, and an address of $x$.

== Application Node

#post.canvas(caption: "Layout of an application node", {
  con("app", (0, 0), show-ports: true, polarities: (-1, -1, +1))

  content((0, 1.2), `fun`)
  content((-0.3, -1.2), `arg`)
  content((+0.3, -1.15), $a$)

  content((4, 0), memory(
    ($a$, [`App` $x$]),
    ($x$,  `fun`, `arg`),
  ))
})

== Lambda Node

#post.canvas(caption: "Layout of a lambda node", {
  con("lam", (0, 0), show-ports: true, polarities: (+1, +1, -1))

  content((0, 1.2), $ell$)
  content((-0.3, -1.17), $v$)
  content((+0.3, -1.2), `bod`)

  content((4, 0), memory(
    ($ell$, [`Lam` $x$]),
    ($x$,  [`VarAddr` $v$], `bod`),
    ($v$, [`Var` $x$]),
  ))
})

Some important things to note:

- The variable and lambda ports hold pointers to each other. This is so that when the lambda node is interacted
  with, the variable node is replaced with an appropriate value.
- A `Var x` port cannot be moved without updating the `VarAddr` value.
- If a variable does not occur in a lambda node's body, the variable is implicitly connected to an eraser. We
  represent this by having the first half of $x$ be `FREE`.
- If this lambda is the identity function, then $v = x'$. This possibility is critical to keep in mind when
  interacting.
- It is nice when reading memory dumps that `Lam x` and `Var x` point to the same address `x`.

Lastly, there is space in $thick #`[` #`Lam` x #`]` thick$ and $thick #`[` #`App` x #`]` thick$ ports to
store a label, so we could have labelled lambdas and application nodes as well, to encode data structures.

== Duplication Node

#post.canvas(caption: "Layout of a duplication node", {
  dup("dup", (0, 0), show-ports: true, polarities: (-1, +1, +1))

  content("dup.label", text(white, $i$))

  content((0, 1.2), `main`)
  content((-0.3, -1.2), $d_1$)
  content((+0.3, -1.2), $d_2$)

  content((4, 0), memory(
    ($d_1$, $#`Dup`_1 thick x$),
    ($d_2$, $#`Dup`_2 thick x$),
    ($x$,  `main`, $#`DupXor`_i thick d_1 xor d_2$),
  ))
})

A few things to note here:
1. We make use of the `label` section of the aux ports of the dup node to store whether it is the first (0) or
   second (1) aux port.
2. We store an $xor$ (XOR) of the two addresses of the aux ports of the duplication node. This is so if we have a hold
   of one of the aux ports, we can find the other by XOR'ing its address with what's stored in $x'$. That is,
   $thick thick d_1 xor d_2 xor d_1 = d_2 thick$.

== Superposition Node

#post.canvas(caption: "Layout of a superposition node", {
  dup("sup", (0, 0), show-ports: true, polarities: (+1, -1, -1))

  content("sup.label", text(white, $i$))

  content((0, 1.2), $s$)
  content((-0.4, -1.17), `fst`)
  content((+0.4, -1.17), `snd`)

  content((4, 0), memory(
    ($s$, $#`Sup`_i thick x$),
    ($x$, `fst`, `snd`),
  ))
})

== Reference Node

#post.canvas(caption: "Layout of a reference node", {
  ref("ref", (0, 0), show-ports: true, polarities: (+1, -1, -1))

  content("ref.label", $r$)

  content((0, 1), $x$)

  content((4, 0), memory(
    ($x$, $#`Ref` thick r$),
  ))
})

Note that $r$ is not an address, but rather just an index into a global array of named nets.

== Root

The root of the net is the single free positive wire that is "held on to" during normalization. This is the very first
port in the heap, the left half of index 0. The second half of index 0 is always free.

= Interactions

Now we will explain the memory transformations that occur during interactions.

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
    ($d_1$, $#`Dup`_1 thick x$),
    ($d_2$, $#`Dup`_2 thick x$),
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

== App - Lam

#post.canvas({
  con("app", (0, 0), show-aux: true, polarities: (-1, -1, +1))
  con("lam", (2, 0))
  wire("lam.0", "app.0")
  wire("lam.1", "lam.2")

  content((-0.3, -1.2), `arg`)
  content((+0.3, -1.15), $a$)

  content((1, -3), memory(
    ($a$, [`App` $x$]),
    ($x$, [`Lam` $y$], `arg`),
    ($y$, [`.` $y'$], $#`Var` x$),
  ))

  translate((6, 0))
  content((-2, -2), $~~>$)

  wire(
    (-0.3, -0.75, +90deg), (+0.3, -0.85, -90deg),
  polarize: (0, 1))

  content((-0.3, -1.2), `arg`)
  content((+0.3, -1.15), $a$)

  content((1, -3), memory(
    ($a$, `arg`),
    ($x$, `FREE`, `FREE`),
    ($y$, `FREE`, `FREE`),
  ))
})

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
    ($a$, `bod`),
    ($x$, `FREE`, `FREE`),
    ($y$, `FREE`, `FREE`),
    ($z$, `arg`),
  ))
})

Problems:
- How is a lambda that erases its argument encoded?
  - Maybe the reference to the `Var` $x$ node is `FREE`. If so, we need to mark `arg` as to-be-erased.

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
    ($d_1$, $#`Dup`_1 thick x$),
    ($d_2$, $#`Dup`_2 thick x$),
    ($x$, $#`Sup`_i thick y$, $#`.`_i thick d_1 xor d_2$),
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
    ($d_1$, $#`Dup`_1 thick x$),
    ($d_2$, $#`Dup`_2 thick x$),
    ($x$, $#`Sup`_j thick y$, $#`.`_i thick d_1 xor d_2$),
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
    ($x$, $#`Dup`_1 thick w$, $#`Dup`_1 thick q$),
    ($y$, $#`Dup`_2 thick w$, $#`Dup`_2 thick q$),
    ($w$, `a`, $#`.`_i thick x xor y$),
    ($q$, `b`, $#`.`_i thick x' xor y'$),
  ), anchor: "north")
})

Notes:
- allocates two new double-wide nodes, which is what we expect.
- frees nothing, so memory is maximally reused.
- it's unclear to me whether it is possible to reach an intermediate net where $thick #`a` = #`Dup`_1 thick x$. If so,
  there can be memory corruption issues here, given that the interaction is written such that we assume $y$ and $y'$
  are distinct from both $d_1$ and $d_2$.

== Dup - Lam

#post.canvas({
  dup("dup", (0, 0), show-aux: true, polarities: (-1, +1, +1))
  con("lam", (2, 0), show-aux: true, polarities: (+1, +1, -1))
  wire("lam.0", "dup.0")

  content("dup.label", text(white, $i$))

  content((-0.3, -1.15), $d_1$)
  content((+0.3, -1.15), $d_2$)

  content((+1.7, -1.15), $z$)
  content((+2.3, -1.15), `bod`)

  content((1, -2), memory(
    ($d_1$, $#`Dup`_1 thick x$),
    ($d_2$, $#`Dup`_2 thick x$),
    ($x$, [`Lam` $y$], $#`.`_i thick d_1 xor d_2$),
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

  content("dup.label", text(white, $i$))
  content("sup.label", text(white, $i$))

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
    ($x$, [`.` $q$], $#`Dup`_1 thick w$),
    ($y$, [`.` $q'$], $#`Dup`_2 thick w$),
    ($z$, $#`Sup`_i thick q$),
    ($w$, `bod`, $#`.`_i thick x' xor y'$),
    ($q$, [`Var` $d_1$], [`Var` $d_2$]),
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

  content("sup.label", text(white, $i$))

  content((-0.3, -1.15), `arg`)
  content((+0.3, -1.10), $a$)

  content((+1.7, -1.15), `a`)
  content((+2.3, -1.15), `b`)

  content((1, -2), memory(
    ($a$, [`App` $x$]),
    ($x$, $#`Sup`_i thick y$, `arg`),
    ($y$, `a`, `b`),
  ), anchor: "north")

  translate((6, 0))
  content((-2, -2), $~~>$)

  content((-0.3, -1), `arg`)
  content((+0.3, -0.95), $a$)

  dup("dup", (1.5, +1.2), angle: 90deg)
  dup("sup", (1.5, -0.2), angle: 90deg)

  content("dup.label", text(white, $i$))
  content("sup.label", text(white, $i$))

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
    ($a$, $#`Sup`_i thick x$),
    ($x$, [`App` $a_1$], [`App` $a_2$]),
    ($y$, `arg`, $#`.`_i thick a_1 xor a_2$),
    ($a_1$, `a`, $#`Dup`_1 thick y$),
    ($a_2$, `b`, $#`Dup`_2 thick y$),
  ), anchor: "north")
})

Notes:
- alocates two new double-wide nodes, which is what we expect.
- frees nothing, so memory is maximally reused.

= Problems
- Single-wire-producing interactions need to be handled specially
  - applying a function to the identity
  - annihilating a sup / dup with loops
- Freeing nodes might not always be safe, there might be a node moved to a location that is then freed...
- Things cannot be moved freely. For example, a `Var` points to its lambda. Thus, the `lambda` cannot be moved unless
  the `Var` is updated.
- No garbage collection, unclear how to safely erase things.
- Garbage collection has to kind of be done during the interactions, there are special cases that tell us whether
  something should be erased (e.g a `FREE` variable port in the first half of `Lam` node). The interactions themselves
  need to handle this.
- If we need 4-bit tags:
  - Make a var point to the lambda node address, not the lambda node slot, this would make it so that `Var` ports have
    a 16-byte aligned addresss.
  - Now all ports have a 16-byte aligned address (except dup nodes' XOR port), so we can have 4-bit tags.
  - We can then reserve the tags `0b1111` and `0b0111` to _both_ be the dup nodes XOR port.
