[title] EZB - Mollusk

[post_title] Mollusk
[post_subtitle] 🐠 + 🐚 = 🌈

[prev_post] ../../../thoughts.html

[body]
# Prelude
## Learning to Fish
As soon as I found out that there were different
shells, I went looking for something better than bash. Bash is fine and all, but
once you see the features alternative shells offer, you'll never switch back.


The [fish shell](https://fishshell.com/) was one of the first shells I found,
and it was the last shell I thought I needed. Everything was so fast. I felt
like it knew what I was going to do, before I even knew what I was going to do.
It's autocomplete is fantastic, the way it fuzzily suggests the directory you
meant to cd into, the deduplication of history, the simpler syntax, etc... all
of that, made fish a pleasure to use.


This doesn't speak to any error on fish's part but, I often found myself pulling
up the Python REPL to do some quick functions or math expressions. Stuff like
this was pretty common:

```python
ezb `Keyword.Import]~>` python3
`Name]Python 3.7.0`

`Keyword.Import]>>>` 0x113e8b3
18081971
`Keyword.Import]>>>` 719 * 114679
82454201
```

So much so that I sometimes even tried running numerical operations like these
on the fish shell itself on accident,

```sh
ezb `Keyword.Import]~>` `String]123` `Number]* 12`
`Name]fish: Unknown command '123'`
```

After accidentally doing this a few times, I eventually thought to myself:
"why shouldn't this work?" I mean, it seems simple enough, just capture stuff
that is a valid arithmetic expression and then run it as Python! But then I
thought about variables, and how I would handle those, what about tuples, or
lambdas, or... At this point I realized that I'd have to capture the entire
Python grammar. Through some weird chain of Google queries, I eventually just
looked up "Python as a shell", and quickly found myself a xonsh.

## Xonsh
Xonsh blew my mind. Xonsh is essentially a superset of Python 3+ syntax
that includes bash-like shell primitives. The entire shell can be treated like a
Python REPL. The environment variables are Python objects. Need to add something
to your path, no problem! Just type `$PATH.append("~/new/path/")`. Need to add
an alias? Just type `aliases["ll"] = "ls -l"`. The benefits of this were huge
and I felt much more at home with this shell. Since it was all Python, modifying
anything was as easy as manipulating a Python object. But of course, it wasn't
perfect...


The autocomplete was nowhere near as nice as fish's. The tab-suggestions that
xonsh would give were always pretty bad. Something like this would often happen:

```sh
ezb `Keyword.Import]~>` ls
lab1.hs

ezb `Keyword.Import]~>` vim lab1.hs
... edit the file ...

ezb `Keyword.Import]~>` mv lab1.hs lab2.hs

ezb `Keyword.Import]~>` vim lab|`String]1.hs`
```


The `|` represents the cursor, and the red text after it represents the
erroneous suggestion. This happened all the damn time, and I despised it. Any
command that previously ran on a file, would have that file autosuggested, even
if that file was clearly not there anymore. I modified xonsh a bunch to not have
this behavior, but the tab-completer still always looked through the history,
even if the auto-suggestions didn't. Fish did not have this behavior, it always
would suggest a file that existed if the previous command succeeded with a
command- line argument that referred to a file.


I wondered if there was a way to combine xonsh and fish, in a way that kept the
best parts of both of them. Ideally, this would be a shell that acted exactly
like xonsh, except for the autocompletion portion, which would act like fish. It
should also be indistinguishable from xonsh to a running process. Could
something like this exist...
