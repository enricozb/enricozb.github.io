#set page(margin: 3.5em)
#show link: underline

#let title(content) = text(weight: 400, size: 28pt)[
  #align(center)[
    #smallcaps[#content]
    #v(-0.5em)
  ]
]

#let section(content) = text(weight: 100, size: 18pt)[
  #smallcaps[#content]
  #v(-0.4em)
]

#let subsection(title, content) = [
  #text(weight: 600, size: 13pt)[#title] #v(-0.8em)
  #pad(left: 10pt)[#text(weight: 400, size: 11pt)[#content]]
]

#let item(title, tech, date, content) = {
  [
    #text(weight: 600, size: 13pt)[#title]
    #h(0.1em)
    #text(weight: 400, size: 12pt, fill: luma(100))[#tech]
    #h(1fr)
    #text(weight: 400, size: 12pt)[#date]

    #v(-0.5em)

    #pad(left: 10pt)[#text(size: 11pt)[#content]]
  ]
}

#let date(date) = [
  #h(1fr)
  #text(weight: 400, size: 11pt)[#date]
]

#title[Enrico Zandomeni Borba]

#grid(
  gutter: 4em,
  columns: (1fr, 1fr),
  [
    #section[Education]

    #item("California Institute of Technology", "", "(2019)")[
      B.S. Computer Science -- Machine Learning Track
    ]
  ],
    [
    #section[Contact]

    +1 (561) 926-1163, #link("mailto:enricozb@gmail.com")[enricozb\@gmail.com], \
    #link("https://ezb.io")[ezb.io], #link("https://github.com/enricozb")[github.com/enricozb]
  ],
)

#section[Work Experience]

#item([Higher Order Company $dot$ Senior SWE], "[Rust, C, Haskell, Agda, CUDA, HVM]", "(Jan 2024 - Present)")[
  Helped create #link("https://github.com/HigherOrderCO/HVM3/tree/main/src")[HVM2/3] -- The
  fastest symmetric interaction combinator runtime. Designed and implemented IO features
  for HVM's CUDA runtime. This is being used as the backbone of HOC's new superposed
  enumeration utility to generate programs satisfying dependently typed constraints at SOTA
  speeds.

  Wrote a DSL for data pipelines of grids of threads with backends in C, CUDA, and Agda. This allowed for a single
  implementation of a multi-threaded interaction net evaluator that transpiled to CPU and GPU runtimes.
]

#item("Freelance / Consultant", "[Rust, Python, Django, Docker]", "(Jan 2023 - Jan 2024)")[
  Contracted at multiple companies (#link("https://ctfd.io/")[CTFd],
  #link("https://www.semasoftware.com/")[Sema Software], #link("https://taqtile.com/")[Taqtile])
  working on a variety of custom software, feature development, codebase maintenance, and customer support.
]

#item([FOSSA $dot$ SWE], "[Typescript, PostgreSQL, Rust, AWS, GCP]", "(Oct 2020 - Jan 2023)")[
  Redesigned a portion of the DB schema leading to 50x faster API response times for the slowest
  endpoints. Designed a migration that updated 50 million rows to the new structure with
  zero-downtime. Led a team of 5 engineers to implement APIs for new search, filtering, and bulk action features enabled by the faster DB.

  Led the development and customer feedback loop of an upcoming AOSP
  Monorepo product. Improved client-side scanning and UI of Monorepo projects by 30x through DB schema
  changes, algorithmic improvements, and cache pre-warming.
]

#item([Google $dot$ SWE], "[C++, BigQuery, Python, Flume]", "(Aug 2019 - Sep 2020)")[
  Worked on the Interactive Questions team under Search. Improved
  the freshness of answers, created an automatic pipeline to initialize and
  monitor data, and built a cache system to speed up pipeline reruns.
]

#item([Van Valen Lab $dot$ Researcher], "[PyTorch, Kubernetes]", "(Sep 2018 - Jun 2019)")[
  Greatly increased (\~65% $arrow$ \~95%) the cell tracking model accuracy on detecting
  divisions through improvements in data augmentation. Created a now patented data curating tool
  #link("https://github.com/vanvalenlab/deepcell-label")[(DeepCell Label)]
  to enable intuitive manual corrections of incorrect inferences. Designed a more efficient file format for inference data for
  #link("https://deepcell-kiosk.readthedocs.io/en/master/")[DeepCell
  Kiosk].
]

// #item("Mitsubishi SWE Intern", "[Python, OpenCV, Embedded]", "(Summer 2018)")[
//   In Osaka, Japan. Worked on the systems division to create the infrastructure
//   for sensor data collection and processing inside next generation vehicles.
//   Constructed a model to detect drowsiness and impairment in drivers using mmWave
//   sensors (AWR1642), camera, and driving data.
// ]

#section[Publications & Presentations]
- #link("https://typst.app/project/p79cg7xe4PUNxioVSgF6rL")[HVM2: Interaction Combinator Evaluator] -- #link("https://www.youtube.com/live/7zZNwLgQCLc?t=28169s")[Video], #link("https://typst.app/project/rFmfnTGooKKbY31rNIu0fq")[Slides]. #date[(ICFP / FProPer 2024)]
- #link("https://www.nature.com/articles/s41592-020-01023-0")[DeepCell: scaling deep learning–enabled cellular image analysis with Kubernetes]. #date[(Nature Methods 2021)]
- #link("https://www.biorxiv.org/content/10.1101/803205v1")[Accurate tracking and lineage construction in live-cell imaging experiments with deep learning]. #date[(bioRxiv 2019)]

#section[Projects & Languages]

#grid(columns: (3fr, 1fr), gutter: 1em)[
  #item([Formalization], "[Lean]", "")[
    The first to formalize #link("https://github.com/leanprover-community/mathlib4/pull/10189")[Buffon's Needle in
    Lean]. \
    Wrote a formally verified #link("https://github.com/enricozb/affine-lean",
    [Affine Lambda Calculus normalizer]). \
    Currently formalizing #link("https://github.com/enricozb/logic", [Rautenberg's #emph[A Concise Introduction to
    Mathematical Logic]]).
  ]


  #item(link("https://docs.rs/intuitive")[Intuitive], "[Rust]", "")[
    A library for creating text-based user interfaces. Inspired
    by React and SwiftUI, with features resembling functional
    components, hooks, and a declarative DSL.
  ]

][
  #subsection[Advanced][
    Rust, Nix, Python, TypeScript, PostgreSQL
  ]

  #subsection[Competent][
    Lean, Agda, Haskell, Golang, OCaml, Bash, Swift, C++, C
  ]
]
