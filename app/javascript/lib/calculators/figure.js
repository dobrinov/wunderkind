// What every calculator's drawing shares: a 440 × 300 box, a figure given in
// its own units fitted into it with room for labels, and the few SVG pieces
// the figures are made of. Everything written into the markup here is a
// number or a label that came from the page's own copy.
export const WIDTH = 440
export const HEIGHT = 300

const INK = "#312e81"
const LINE = "#5048e5"
const FILL = "#e2e4ff"
const MUTED = "#666680"
const PAPER = "#f1f2ff"

// Fits points given in the figure's units (y up) into the box: returns the
// function that places one.
export function fit(points, { padX = 64, padTop = 26, padBottom = 46 } = {}) {
  const xs = points.map((p) => p[0])
  const ys = points.map((p) => p[1])
  const minX = Math.min(...xs), maxX = Math.max(...xs)
  const minY = Math.min(...ys), maxY = Math.max(...ys)
  const scale = Math.min((WIDTH - 2 * padX) / (maxX - minX || 1), (HEIGHT - padTop - padBottom) / (maxY - minY || 1))
  const left = (WIDTH - (maxX - minX) * scale) / 2
  const bottom = HEIGHT - padBottom - ((HEIGHT - padTop - padBottom) - (maxY - minY) * scale) / 2

  return ([x, y]) => [left + (x - minX) * scale, bottom - (y - minY) * scale]
}

const n = (value) => value.toFixed(1)

export const polygon = (points) =>
  `<polygon points="${points.map((p) => `${n(p[0])},${n(p[1])}`).join(" ")}" fill="${FILL}" stroke="${LINE}" stroke-width="3" stroke-linejoin="round"/>`

export const dashed = (from, to, color = MUTED) =>
  `<line x1="${n(from[0])}" y1="${n(from[1])}" x2="${n(to[0])}" y2="${n(to[1])}" stroke="${color}" stroke-width="2.5" stroke-dasharray="6 5"/>`

// A label, with a pale halo painted under its letters: on a solid, some edge
// or other runs behind wherever a label can go, and without the halo the line
// reads as a strike through the number.
export const label = (at, text, { anchor = "middle", color = INK, dx = 0, dy = 0 } = {}) =>
  `<text x="${n(at[0] + dx)}" y="${n(at[1] + dy)}" text-anchor="${anchor}" font-weight="800" font-size="18" fill="${color}" ` +
  `stroke="${PAPER}" stroke-width="6" stroke-linejoin="round" paint-order="stroke">${text}</text>`

// The little square that marks a right angle at `corner`, along two unit
// directions in screen space.
export function rightAngle(corner, along, up, size = 14) {
  const a = [corner[0] + along[0] * size, corner[1] + along[1] * size]
  const b = [a[0] + up[0] * size, a[1] + up[1] * size]
  const c = [corner[0] + up[0] * size, corner[1] + up[1] * size]
  return `<path d="M ${n(a[0])} ${n(a[1])} L ${n(b[0])} ${n(b[1])} L ${n(c[0])} ${n(c[1])}" fill="none" stroke="${LINE}" stroke-width="2"/>`
}

export const middle = (p, q) => [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2]

// How many pixels one unit of the figure is, once fitted.
export const scaleOf = (place) => Math.abs(place([1, 0])[0] - place([0, 0])[0])

export const line = (from, to, { color = LINE, width = 3 } = {}) =>
  `<line x1="${n(from[0])}" y1="${n(from[1])}" x2="${n(to[0])}" y2="${n(to[1])}" stroke="${color}" stroke-width="${width}" stroke-linecap="round"/>`

// A filled shape with no outline, for the faces of a solid whose edges are
// drawn one by one (some of them dashed).
export const face = (points, opacity = 1) =>
  `<polygon points="${points.map((p) => `${n(p[0])},${n(p[1])}`).join(" ")}" fill="${FILL}" fill-opacity="${opacity}"/>`

export const circle = (centre, radius) =>
  `<circle cx="${n(centre[0])}" cy="${n(centre[1])}" r="${n(radius)}" fill="${FILL}" stroke="${LINE}" stroke-width="3"/>`

export const dot = (at) => `<circle cx="${n(at[0])}" cy="${n(at[1])}" r="3.5" fill="${LINE}"/>`

// An ellipse seen as the rim of a round solid: the near half solid, the far
// half dashed unless `open` (a top rim, seen whole).
export function rim(centre, rx, ry, { open = false, fill = false } = {}) {
  const [x, y] = centre
  const near = `<path d="M ${n(x - rx)} ${n(y)} A ${n(rx)} ${n(ry)} 0 0 0 ${n(x + rx)} ${n(y)}" fill="none" stroke="${LINE}" stroke-width="3"/>`
  const far = `<path d="M ${n(x - rx)} ${n(y)} A ${n(rx)} ${n(ry)} 0 0 1 ${n(x + rx)} ${n(y)}" fill="none" stroke="${open ? LINE : MUTED}" stroke-width="${open ? 3 : 2.5}"${open ? "" : ' stroke-dasharray="6 5"'}/>`
  const inside = fill ? `<ellipse cx="${n(x)}" cy="${n(y)}" rx="${n(rx)}" ry="${n(ry)}" fill="${FILL}"/>` : ""
  return inside + far + near
}

export const GREY = "#50506b"
