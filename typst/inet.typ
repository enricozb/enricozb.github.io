#import "@preview/cetz:0.3.4": draw, canvas

#let port = (name, pos, dir: 0deg) => {
  import draw: *

  group(name: name, {
    translate(pos)
    rotate(dir)
    // scale(1.5)
    anchor("p", (0, 0))
    anchor("c", (0, 0.5))
  })
}

#let agent = (..agent) => (name: none, pos: (0, 0), rot: 0deg, show-aux: false, show-main: false) => {
  import draw: *

  let style = agent.at("style", default: ())
  let stroke_style = agent.at("stroke", default: (:))

  group(name: name, {
    translate(pos)
    rotate(rot)
    translate((0, -calc.sqrt(3)/4))
    stroke(2pt)
    line((-.5, 0), (.5, 0), (0, calc.sqrt(3)/2), close: true, ..style, stroke: (thickness: 1pt, ..stroke_style))
    port("0", (0, calc.sqrt(3)/2))
    port("1", (-1/2+1/3, 0), dir: 180deg)
    port("2", (+1/2-1/3, 0), dir: 180deg)

    if show-main {
      bezier("0.p", "0.p", "0.c", "0.c", stroke: black)
    }

    if show-aux {
      bezier("1.p", "1.p", "1.c", "1.c", stroke: black)
      bezier("2.p", "2.p", "2.c", "2.c", stroke: black)
    }
  })
}

#let era = (name: none, pos: none, rot: 0deg) => {
  import draw: *

  group(name: name, {
    translate(pos)
    rotate(rot)
    circle((0, 0), radius: 2pt, fill: black)
    port("0", (0, 0))
  })
}

#let link = (a, b, main: false, thickness: 1pt, dash: none) => {
  import draw: stroke, bezier, on-layer

  let stroke-style = (paint: if main {red} else {black}, thickness: thickness, dash: dash)

  on-layer(-1, bezier(a + ".p", b + ".p", a + ".c", b + ".c", stroke: stroke-style))
}

#let con = agent()

#let dup = agent(style: (fill: black))
