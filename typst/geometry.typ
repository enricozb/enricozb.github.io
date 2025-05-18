#import "@preview/cetz:0.3.4"

#let arrow(position, angle, stroke: black + 1pt) = {
  cetz.draw.group({
    cetz.draw.translate(position)
    cetz.draw.rotate(angle)
    cetz.draw.line((-0.1, -0.1), (0, 0), (-0.1, 0.1), stroke: stroke)
  })
}

#let scale-vec((x, y, z), s) = {
  (x * s, y * s, z * s)
}

#let bezier-point(t, p1, p2, c1, c2) = {
  let u = 1.0 - t;
  let tt = t * t;
  let uu = u * u;
  let uuu = uu * u;
  let ttt = tt * t;

  let (x1, y1, z1) = scale-vec(p1, uuu);
  let (x2, y2, z2) = scale-vec(c1, 3.0 * uu * t);
  let (x3, y3, z3) = scale-vec(c2, 3.0 * u * tt);
  let (x4, y4, z4) = scale-vec(p2, ttt);

  (
    x1 + x2 + x3 + x4,
    y1 + y2 + y3 + y4,
    z1 + z2 + z3 + z4,
  )
}

#let bezier-derivative(t, (p1x, p1y, _), (p2x, p2y, _), (c1x, c1y, _), (c2x, c2y, _)) = {
  let u = 1 - t
  let dx = (
    3 * u * u * (c1x - p1x) +
    6 * u * t * (c2x - c1x) +
    3 * t * t * (p2x - c2x)
  )
  let dy = (
    3 * u * u * (c1y - p1y) +
    6 * u * t * (c2y - c1y) +
    3 * t * t * (p2y - c2y)
  )
  (dx, dy)
}

#let bezier-angle(t, p1, p2, c1, c2) = {
  let (dx, dy) = bezier-derivative(t, p1, p2, c1, c2)
  if dx == 0 {
    dy.signum() * 90deg
  } else {
    calc.atan(dy / dx)
  } + if dx < 0 { 180deg } else { 0deg }
}
