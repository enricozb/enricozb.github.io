#import "@preview/cetz:0.3.4"

#let tag-html(content, attrs: (:)) = html.elem("html",  attrs: attrs)[#content]
#let tag-head(content, attrs: (:)) = html.elem("head",  attrs: attrs)[#content]
#let tag-meta(attrs: (:))          = html.elem("meta",  attrs: attrs)
#let tag-link(attrs: (:))          = html.elem("link",  attrs: attrs)
#let tag-body(content, attrs: (:)) = html.elem("body",  attrs: attrs)[#content]
#let tag-title(content)            = html.elem("title")[#content]
#let tag-script(attrs: (:))        = html.elem("script", attrs: attrs)

#let tag-div(content, class: "") = html.elem("div", attrs: (class: class))[#content]
#let tag-p(content, class: "")   = html.elem("p", attrs: (class: class))[#content]

#let header = [
  #tag-head[
    #tag-meta(attrs: (name: "viewport", content: "width=device-width, initial-scale=1"))
    #tag-meta(attrs: (http-equiv: "content-type", content: "text/html; charset=UTF-8"))

    #tag-link(attrs: (rel: "stylesheet", href: "/css/thoughts.css"))
    #tag-link(attrs: (rel: "stylesheet", href: "/js/katex/katex.min.css"))

    #tag-script(attrs: (defer: "", src: "/js/katex/katex.min.js"))
    #tag-script(attrs: (defer: "", src: "/js/katex/contrib/auto-render.min.js"))

    #tag-title("Enrico Z. Borba - Thoughts")
  ]
]

#let footer = [
  #tag-div(class: "footer")[
    made with #link("https://www.youtube.com/watch?v=Ssd3U_zicAI")[love] by
    #link("https://github.com/enricozb/enricozb.github.io/commits/master")[hand],
    though sometimes with #link("https://typst.app/")[typst].
  ]
]

#let nav(title: none, date: none) = [
  #tag-div(class: "header")[
    #tag-div(class: "nav left")[
      #tag-div[#link("/")[home]]
      #tag-div[#link("/thoughts")[thoughts]]
    ]
    #tag-div(class: "center")[
      #tag-div(class: "title")[#title]
      #tag-div(class: "subtitle")[#date]
    ]
  ]
]

#let note(content) = tag-div(class: "note")[#content]

#let center(content) = tag-div(class: "center")[#content]

#let body(content) = [
  #tag-div(class: "main")[
    #tag-div(class: "text")[
      #content
    ]
  ]
]

#let in_canvas = counter("canvas")

#let canvas(code) = {
  in_canvas.update(1)

  center(html.frame(cetz.canvas(code)))

  in_canvas.update(0)
}

#let spoiler(name, content) = [
  #center[
    #html.elem("details")[
      #html.elem("summary")[#name]
      #content
    ]
  ]
]

#let post(title: none, date: none, content) = [
  #show math.equation.where(block: false): it => {
    if in_canvas.get().at(0) == 1 {
      it
    } else {
      html.elem("span", attrs: (role: "math"), html.frame(it))
    }
  }

  #show math.equation.where(block: true): it => {
    if in_canvas.get().at(0) == 1 {
      it
    } else {
      html.elem("figure", attrs: (role: "math"), html.frame(it))
    }
  }

  #tag-html[
    #header

    #tag-body[
      #nav(title: title, date: date)
      #body(content)
    ]

    #footer
  ]
]
