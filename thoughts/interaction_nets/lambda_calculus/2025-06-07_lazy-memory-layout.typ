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
  to implement a lazy normalizer. This proved to be false.
]

#let (era, con, dup, ref) = inets.with-kinds(
  era: inets.nilary-node,
  con: inets.stroked-node,
  dup: inets.filled-node,
  ref: inets.reference-node,
)

#let wire = inets.wire.with(polarize: true)

#let slot(tag, ..args) = {
  let (addr, label) = if args.pos().len() == 0 {
    (none, none)
  } else if args.pos().len() == 1 {
    (args.pos().at(0), none)
  } else {
    (args.pos().at(1), args.pos().at(0))
  }

  $#text(size: 14pt, `[`) #{tag}_#label thick #addr #text(size: 14pt, `]`)$
}


#let memory(..addresses) = $
  #for (addr, ..blocks) in addresses.pos() {
    $
      #addr &: #for block in blocks {
        if type(block) == array {
          slot(..block)
        } else {
          slot(block)
        }
      } \
    $
  }
$

= Overview

This post explains a chain-free#footnote[In most interaction net runtimes, there is a way to explicitly represent
a wire. Sequences of these wires can form, which I'll refer to as a _chain_. These are essentially indirections
that can increase in length as the network is reduced. The memory representation detailed in this post makes such
chains unrepresentable, and thus interactions are always constant time. Whether or not this is practically useful
is unclear. There are known algorithms where chain lengths grow logarithmically in the number of interactions, and
the implementations of the interactions in such a runtime can be much simpler than what is presented here.] memory
layout for lazy normalization and details the graph traversal using this layout. The memory layout includes both
how nodes and wires are represented, and then the memory transformations that happen for each interaction.

= Allocation

Ideally a VM's memory layout shouldn't care about how the allocator keeps track of free memory, but unfortunately the
memory representation presented here will have such a coupling. This is because some of the node representations make
use of free regions in memory to represent special values. So, we'll need to describe the allocator as well.

The allocator first allocates a single memory arena as large as the OS will allow. We'll refer to this region of memory
as the _heap_. The heap is aligned to the nearest 16 bytes. This is because the allocator deals with double-word
(128-bit) values.

The allocator has a simple API:

#post.code(caption: "Allocator API",
  ```rust
  /// An 8-byte-aligned address.
  pub struct Addr(*const u64);

  /// Returns a 16-byte aligned address.
  fn alloc_double_word(&mut self) -> Option<Addr>

  /// Frees an 8-byte aligned address.
  fn free_single_word(&mut self, addr: Addr)

  /// Frees a 16-byte aligned address.
  fn free_double_word(&mut self, addr: Addr)
  ```
)

== Memory Reuse

The allocator uses a #link("https://en.wikipedia.org/wiki/Free_list")[free list] to track free memory regions. This
attempts to maximise the reuse of memory. If a single word is freed, the allocator checks if its neighboring half
is also free. If so, the whole 128-bit value is freed. Since double words can only be allocated at 16-byte-aligned
addresses, a free single word will not be reused unless its neighboring half is also free. _This fact is explicitly
relied on by the memory representation of nets. Specifically, some owned double-word values will keep one half
free to represent a special form of the value_.

= In-Memory Representation of Nodes

== Negative Ports (or Positive Wires)

We will be storing polarized $k$-SIC nodes. Roughly, every 64-bit value on the heap is a negative port on the net. The
way I prefer to view this is: values on the heap tell you what is on the other side of the positive end of a wire.
There are some exceptions to this, but this is broadly the case.

Every double-word value on the heap, except the root at index 0, describes some node. For nodes with two negative
ports, each word is one of those ports. This is because negative ports are connected to the positive end of a wire.
The exception noted above occurs for nodes with a single negative port: one word is that negative port and the
other is some node-dependent information.

The memory layout of these 64-bit, single-word, values is:

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
  #[repr(u8)]
  pub enum Tag {
    /// ========================= positive k-SIC wires =========================

    /// A positive eraser.
    Nul = 0b0001,
    /// The return port of an application node.
    App = 0b0010,
    /// The main port of a lambda node.
    Lam = 0b0011,
    /// The first aux port of a lambda node, the variable.
    Var = 0b0100,
    /// An aux port of a duplication node.
    Dup = 0b0101,
    /// The main port of a superposition node.
    Sup = 0b0110,
    /// Reference nodes that map to a net with a single free positive wire.
    Ref = 0b0111,

    /// ========================= node-specific values =========================

    /// An XOR of the addresses of a dup's aux ports.
    ///
    /// This has two values because addresses to dup aux ports are 8-byte
    /// aligned. So, only the bottom 3 bits are 0. We cover both cases where the
    /// 4th lowest bit may be 0 or 1 And map them to the same variant.
    ///
    /// When creating DupXor values, we use 0b0000 to not affect the 4th bit.
    DupXor = 0b0000 | 0b1000,

    /// The address of a lambda's variable.
    ///
    /// Because the label bits of this 64-bit value are unused, we can store
    /// whether this addr is the upper or lower half, like for the Sup tag. So,
    /// unlike the DupXor value, we don't need two tags, as we're not storing an
    /// 8-byte aligned address in the addr bits.
    VarAddr = 0b1001,
  }
  ```
)

The highest 16-bits are labels used by the duplication and superposition nodes, where each label represents a
different kind of node. The application/lambda nodes are an additional kind of node, so the $k$ in $k$-SIC here
is equal to $2^16 + 1$.

The 44-bit addresses are actually 48-bit user-space pointers into the heap#footnote[This representation
explicitly relies on the fact that most 64-bit processors do not use the upper 16-bits of addressing space.]. Since
these pointers are 16-byte aligned, the bottom 4 bits are all 0. Thus, we can store the `Tag` inline with these
addresses. Note that not all node tags store an address.

Here is a summary of how each tag uses its bits:

#post.canvas(caption: "Tag-dependent port interpretations", {
  content((0, 0),
    ```text
    [       ][ dw addr ][     App ]
    [       ][ dw addr ][     Lam ]
    [       ][ dw addr ][     Var ]
    [       ][         ][     Nul ]
    [ 0 | 1 ][ dw addr ][     Dup ]
    [ label ][ dw addr ][     Sup ]
    [       ][   index ][     Ref ]

    [ label ][     xor ][  DupXor ]
    [  half ][ dw addr ][ VarAddr ]
    ```
  )

  content((3.2, 0.8), [$stretch(brace.r, size: #8em)$ positive $k$-SIC ports], anchor: "west")

  content((3.2, -1.6), [$stretch(brace.r, size: #2em)$ node-specific values], anchor: "west")
})

Some additional clarity on the notation:
  - `dw addr` is a double-word (128-bit) aligned address.
  - `0 | 1` is a boolean that a `Dup` port uses to know which (first or second) aux port this is.
  - `index` is an index into a global array $cal(R)$ of references or named nets.
  - `xor` is a 45-bit value (not a typo#footnote[While this space is typically reserved only for 44-bit values, the
    45th bit is actually stored as part of the `tag`. This is done by having two possible values be interpreted as a
    `DupXor` tag, `0b0000` and `0b1000`. Notice that the bottom three bits are the same for both of these tags, but
    the 4th bit can be either one or zero. This 4th bit is the 45th bit of the xor value.]) that is used to determine
    the location of a dup aux port, given that you know the location of the other one already.
  - `half` is a boolean indicating whether the `dw addr` points to the first or second half of a double-word#footnote[
    We could have also done the same two-tag trick as `DupXor` uses to store a 45-bit address. However, `VarAddr` has
    no label, so this is arguably a better use of the space available.].

== Notation

Ports which make use of their address bits expect a specific structure at that address in the heap. We will detail
each of those structures now. In the memory layouts that follow, we'll use code-script to represent arbitrary
values on the heap (e.g. `fun` or `arg`). Math-script is used to represent memory addresses (e.g. $a$ or $x$).

When displaying these nodes, memory addresses with only a single port next to them are 8-byte aligned addresses, and
addresses with two ports are 16-byte aligned. For example, consider the diagram

#post.canvas({
  content((4, 0), memory(
    ($a$, (`App`, $x$)),
    ($x$, `fun`, `arg`),
  ))
})

Above, $a$ is 8-byte aligned while $x$ is 16-byte aligned. Lastly, an address with an apostrophe is the second
half of a 16-byte-aligned address. For example, $thick x'$ would refer to `arg` above.

Additionally, if we show a port with a tag of `.`, this implies that only one tag is possible given the context. This
is made possibe to decrease noise in the memory diagrams. For example, we will see that in an example layout like this

#post.canvas({
  content((4, 0), memory(
    ($a$, (`Lam`, $x$)),
    ($x$, (`.`, $x$), `arg`),
  ))
})

The only possibility for the tag in #slot(`.`, $x$) is `VarAddr`, since it is pointed to by a #slot(`Lam`, $x$) node.

Lastly, we use subscripts to refer to the `label` portion of a port. For example, $thick #`[` #`Sup`_i thick x #`]`$
is a port with the `Sup` tag, label $i$, and an address of $x$.

== Application Node

#post.canvas(caption: "Layout of an application node", {
  con("app", (0, 0), show-ports: true, polarities: (-1, -1, +1))

  content((0, 1.2), `fun`)
  content((-0.3, -1.2), `arg`)
  content((+0.3, -1.15), $a$)

  content((4, 0), memory(
    ($a$, (`App`, $x$)),
    ($x$, `fun`, `arg`),
  ))
})

== Lambda Node

#post.canvas(caption: "Layout of a lambda node", {
  con("lam", (0, 0), show-ports: true, polarities: (+1, +1, -1))

  content((0, 1.2), $ell$)
  content((-0.3, -1.17), $v$)
  content((+0.3, -1.2), `bod`)

  content((4, 0), memory(
    ($ell$, (`Lam`, $x$)),
    ($x$,  (`VarAddr`, $v$), `bod`),
    ($v$, (`Var`, $x$)),
  ))
})

Some important things to note:

- The variable and lambda ports hold pointers to each other. This is so that when the lambda node is interacted
  with, the variable node is replaced with an appropriate value.
- A `Var x` port cannot be moved without updating the `VarAddr` value.
- If a variable does not occur in a lambda node's body, the variable is implicitly connected to an eraser. We
  represent this by having $v = 0$, since the root port can never have a `Var`.
- If this lambda is the identity function, then $v = x'$.
- Lambda nodes take up a variable amount of memory.
  - The identity lambda and a lambda that erases its variable both use 3 64-bit values of memory.
  - Lambda nodes that use their variables and are not an identity take up 4 64-bit values of memory.
- It is nice when reading memory dumps that #slot(`Lam`, $x$) and #slot(`Var`, $x$) point to the same address `x`.

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
    ($d_1$, (`Dup`, 1, $x$)),
    ($d_2$, (`Dup`, 2, $x$)),
    ($x$,  `main`, (`DupXor`, $i$, $d_1 xor d_2$)),
  ))
})

A few things to note here:
- We make use of the `label` section of the aux ports of the dup node to store whether it is the first (0) or
  second (1) aux port.
- We store an $xor$ (XOR) of the two addresses of the aux ports of the duplication node. This is so if we have a hold
  of one of the aux ports, we can find the other by XOR'ing its address with what's stored in $x'$. That is,
  $thick thick d_1 xor d_2 xor d_1 = d_2 thick$.
- If one of the aux ports of this dup node was erased, say $d_1$, then $d_1 = 0$ and the address in the `DupXor`
  is $d_2$. If both aux ports have been erased, then the address in the `DupXor` port is 0.

== Superposition Node

#post.canvas(caption: "Layout of a superposition node", {
  dup("sup", (0, 0), show-ports: true, polarities: (+1, -1, -1))

  content("sup.label", text(white, $i$))

  content((0, 1.2), $s$)
  content((-0.4, -1.17), `fst`)
  content((+0.4, -1.17), `snd`)

  content((4, 0), memory(
    ($s$, (`Sup`, $i$, $x$)),
    ($x$, `fst`, `snd`),
  ))
})

== Reference Node

#post.canvas(caption: "Layout of a reference node", {
  ref("ref", (0, 0), show-ports: true, polarities: (+1, -1, -1))

  content("ref.label", $r$)

  content((0, 1), $x$)

  content((4, 0), memory(
    ($x$, (`Ref`, $r$)),
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
    ($a$, (`App`, $x$)),
    ($x$, `Nul`, `arg`),
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
    ($d_1$, (`Dup`, 1, $x$)),
    ($d_2$, (`Dup`, 2, $x$)),
    ($x$, `Nul`, (`.`, $i$, $d_1 xor d_2$)),
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
    ($a$, (`App`, $x$)),
    ($x$, (`Lam`, $y$), `arg`),
    ($y$, (`.`, $y'$), (`Var`, $y$)),
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
    ($a$, (`App`, $x$)),
    ($x$, (`Lam`, $y$), `arg`),
    ($y$, (`.`, $z$), `bod`),
    ($z$, (`Var`, $y$)),
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
    ($d_1$, (`Dup`, 1, $x$)),
    ($d_2$, (`Dup`, 2, $x$)),
    ($x$, (`Sup`, $i$, $y$), (`.`, $i$, $d_1 xor d_2$)),
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
    ($d_1$, (`Dup`, 1, $x$)),
    ($d_2$, (`Dup`, 2, $x$)),
    ($x$, (`Sup`, $j$, $y$), (`.`, $i$, $d_1 xor d_2$)),
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
    ($d_1$, (`Sup`, $j$, $x$)),
    ($d_2$, (`Sup`, $j$, $y$)),
    ($x$, (`Dup`, 1, $w$), (`Dup`, 1, $q$)),
    ($y$, (`Dup`, 2, $w$), (`Dup`, 2, $q$)),
    ($w$, `a`, (`.`, $i$, $x xor y$)),
    ($q$, `b`, (`.`, $i$, $x' xor y'$)),
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
    ($d_1$, (`Dup`, 1, $x$)),
    ($d_2$, (`Dup`, 2, $x$)),
    ($x$, (`Lam`, $y$), (`.`, $i$, $d_1 xor d_2$)),
    ($y$, (`.`, $z$), `bod`),
    ($z$, (`Var`, $x$)),
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
    ($d_1$, (`Lam`, $x$)),
    ($d_2$, (`Lam`, $y$)),
    ($x$, (`.`, $q$), (`Dup`, 1, $w$)),
    ($y$, (`.`, $q'$), (`Dup`, 2, $w$)),
    ($z$, (`Sup`, $i$, $q$)),
    ($w$, `bod`, (`.`, $i$, $x' xor y'$)),
    ($q$, (`Var`, $x$), (`Var`, $y$)),
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
    ($a$, (`App`, $x$)),
    ($x$, (`Sup`, $i$, $y$), `arg`),
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
    ($a$, (`Sup`, $i$, $x$)),
    ($x$, (`App`, $a_1$), (`App`, $a_2$)),
    ($y$, `arg`, (`.`, $i$, $a_1 xor a_2$)),
    ($a_1$, `a`, (`Dup`, 1, $y$)),
    ($a_2$, `b`, (`Dup`, 2, $y$)),
  ), anchor: "north")
})

Notes:
- alocates two new double-wide nodes, which is what we expect.
- frees nothing, so memory is maximally reused.

= Walk Optimization
When performing #link("2025-05-18_lazy-strict-eval.html")[lazy reduction], we traverse the net in a specific way
to find active pairs. Once a single active pair is reduced, we restart the walk at the root. We repeat this until
a walk is performed that came across no active pairs. Since the walk procedure is deterministic, we can optimize
the restarting step by restarting the walk at the most recently entered aux port after a single active pair reduction.
In order to do this, we need to maintain a stack of nodes that were entered in phase 2#footnote[this is the same "phase
2" that was described in the #link("2025-05-18_lazy-strict-eval.html")[lazy reduction post].], and pop from that stack
during walk restarts. Nodes visited during phase 1 do not need to be tracked, as they cannot ever be interacted with,
and in some sense are already normalized.

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
