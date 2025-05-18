#import "@preview/cetz:0.3.4"
#import "geometry.typ": *

// A node in an interaction net.
#let node(
  name,
  position,
  angle: 0deg,
  kind: none,
  kinds: (:),
  show-ports: false,
  show-main: false,
  show-aux: false,
  polarities: (),
  debug: false
) = {
  let kind = kinds.at(kind)
  let shape = kind.at("shape")
  let ports = kind.at("ports", default: ())
  let label = kind.at("label", default: (0, 0))

  cetz.draw.group(name: name, {
    cetz.draw.translate(position)
    cetz.draw.rotate(angle)
    cetz.draw.group({shape})
    cetz.draw.anchor("label", label)

    if debug {
      cetz.draw.content("label", text(red, name), anchor: "mid")
    }

    for (i, (x, y)) in ports.enumerate() {
      let is-main = i == 0

      cetz.draw.group(name: str(i), {
        cetz.draw.anchor("p", (x, y))
        // The control point is above the port if it is the principal port (i == 0)
        // and below the point if it is an aux port (i != 0)
        cetz.draw.anchor("c", (x, if i == 0 {y + 0.5} else {y - 0.5}))

        if show-ports or (show-aux and not is-main) or (show-main and is-main){
          let polarity = polarities.at(i, default: none)

          let start = (x, y)
          let length = if polarity == 1 { 0.4 } else { 0.3 }
          let end = (x, if is-main {y + length} else {y - length})
          cetz.draw.line(start, end)

          if polarity == 1 {
            arrow(end, if i == 0 { 90deg } else { -90deg })
          } else if polarity == -1 {
            arrow(end, if i == 0 { -90deg } else { 90deg })
          }
        }
      })
    }
  })
}

// A wire between two ports. Intermediate points are interpolated through.
// `start`, `next`, and elements of `..points` can be either ports `"<node>.<port>"`
// or `(x, y, deg)`.
#let wire(start, ..points, dash: none, polarize: false, stroke: black, layer: -1) = {
  let arrows = if polarize == true {
    (0.5 * points.pos().len(), )
  } else if type(polarize) == int or type(polarize) == float {
    (polarize * points.pos().len(), )
  } else if type(polarize) == array {
    polarize.map(p => p * points.pos().len())
  } else {
    ()
  }

  cetz.draw.on-layer(layer, {
    for (i, point) in points.pos().enumerate() {
      // Compute the point and control for the start of the curve.
      let (p1, c1) = if type(start) == str {
        (start + ".p", start + ".c")
      } else {
        let (x, y, ..deg) = start
        let deg = deg.at(0, default: 0deg)
        ((x, y), (x + 0.5 * calc.cos(deg), y + 0.5 * calc.sin(deg)))
      }

      // Compute the point and control for the end of the curve.
      let (p2, c2) = if type(point) == str {
        (point + ".p", point + ".c")
      } else {
        let (x, y, ..deg) = point
        let deg = deg.at(0, default: 0deg)
        ((x, y), (x - 0.5 * calc.cos(deg), y - 0.5 * calc.sin(deg)))
      }

      start = point

      cetz.draw.bezier(p1, p2, c1, c2, stroke: stroke)

      for arrow-t in arrows {
        if 0 < (arrow-t - i) and (arrow-t - i) <= 1 {
          let t = arrow-t - i

          cetz.draw.get-ctx(ctx => {
            let (ctx, p1, p2, c1, c2) = cetz.coordinate.resolve(ctx, p1, p2, c1, c2)
            let angle = bezier-angle(t - 0.05, p1, p2, c1, c2)
            let position = bezier-point(t, p1, p2, c1, c2)
            // cetz.draw.content(position, [#angle])
            arrow(position, angle, stroke: stroke)
          })
        }
      }
    }
  })
}

#let with-kinds(..kinds) = {
  let kinds = kinds.named()

  kinds.keys().map(kind => node.with(kind: kind, kinds: kinds))
}

#let nilary-node = (
  "shape": {
    cetz.draw.stroke(none)
    cetz.draw.fill(black)
    cetz.draw.circle((0, 0), radius: 3pt)
  },
  "ports": ((0, 0),),
  "label": (0, -0.3)
)

#let stroked-node = (
  "shape": {
    cetz.draw.stroke(1pt)
    cetz.draw.fill(white)
    cetz.draw.line((-0.5, -calc.sqrt(3)/4), (0.5, -calc.sqrt(3)/4), (0, calc.sqrt(3)/4), close: true)
  },
  "ports": ((0, calc.sqrt(3)/4), (-0.3, -calc.sqrt(3)/4), (0.3, -calc.sqrt(3)/4)),
  "label": (0, -0.1)
)

#let filled-node = (
  "shape": {
    cetz.draw.stroke(1pt)
    cetz.draw.fill(black)
    cetz.draw.line((-0.5, -calc.sqrt(3)/4), (0.5, -calc.sqrt(3)/4), (0, calc.sqrt(3)/4), close: true)
  },
  "ports": ((0, calc.sqrt(3)/4), (-0.3, -calc.sqrt(3)/4), (0.3, -calc.sqrt(3)/4)),
  "label": (0, -0.1)
)

#let reference-node = (
  "shape": {
    cetz.draw.stroke(1pt)
    cetz.draw.rect((-0.3, -0.3), (0.3, 0.3))
  },
  "ports": ((0, 0.3),),
  "label": (0, 0),
)

#let double-stroked-node = (
  "shape": {
    cetz.draw.stroke(1pt)
    cetz.draw.fill(white)
    cetz.draw.line((-0.5, -calc.sqrt(3)/4), (0.5, -calc.sqrt(3)/4), (0, calc.sqrt(3)/4), close: true)
    cetz.draw.scale(0.7, origin: (0, -calc.sqrt(3)/4 * 1/3))
    cetz.draw.line((-0.5, -calc.sqrt(3)/4), (0.5, -calc.sqrt(3)/4), (0, calc.sqrt(3)/4), close: true)
    // cetz.draw.circle((0, 0), radius: 1pt)
  },
  "ports": ((0, calc.sqrt(3)/4), (-0.4, -calc.sqrt(3)/4), (0.4, -calc.sqrt(3)/4)),
  "label": (0, -0.1)
)
