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

export const label = (at, text, { anchor = "middle", color = INK, dx = 0, dy = 0 } = {}) =>
  `<text x="${n(at[0] + dx)}" y="${n(at[1] + dy)}" text-anchor="${anchor}" font-weight="800" font-size="17" fill="${color}">${text}</text>`

// The little square that marks a right angle at `corner`, along two unit
// directions in screen space.
export function rightAngle(corner, along, up, size = 14) {
  const a = [corner[0] + along[0] * size, corner[1] + along[1] * size]
  const b = [a[0] + up[0] * size, a[1] + up[1] * size]
  const c = [corner[0] + up[0] * size, corner[1] + up[1] * size]
  return `<path d="M ${n(a[0])} ${n(a[1])} L ${n(b[0])} ${n(b[1])} L ${n(c[0])} ${n(c[1])}" fill="none" stroke="${LINE}" stroke-width="2"/>`
}

export const middle = (p, q) => [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2]
