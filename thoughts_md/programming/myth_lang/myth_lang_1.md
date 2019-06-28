[title] EZB - MythLang

[post_title] MythLang 1
[post_subtitle] Introduction

[prev_post] ezb.io/thoughts
[next_post] myth_lang_2.html

[body]
[Myth](https://github.com/enricozb/CS81-2019) is my attempt to realize some of
the ideas I had in the currently incomplete series of [idk-lang
posts](https://ezb.io/thoughts/programming/idk_lang/idk_lang_1.html).  I
started this as a senior project with a professor while doing my undergrad at
Caltech, and I'm going to try to blog out my progress here. Honestly, the lack
of literature on languages that have both type-inference, polymorphism, and
mutability, is the main reason I'm writing this. Hopefully someone will find
something useful here.

It's called Myth because I don't think it'll ever really exist how I want it
to. What I want is probably too impractical to exist anyways, and I constantly
keep going back and forth during language design when trying to add a feature
and understand the tradeoffs of doing so.

Myth is written in OCaml (until it maybe becomes self-hosted), so you'll
probably want to brush up on the OCaml syntax before digging too deep here.

We'll start off with lexing/parsing first. Lexing in particular is
unfortunately a bit involved since I wanted a whitespace-sensitive language.

