import { Controller } from "@hotwired/stimulus"

// „Задачи за съвместна работа": two taps fill a pool alone in t₁ and t₂
// hours. What can be added is the part of the pool each fills in one hour —
// 1/t₁ and 1/t₂ — so the working is done in fractions, never decimals, and
// the bar is the pool itself: every hour both taps add the same two pieces
// until it is full. The times themselves are only set side by side at the
// end, to show that adding them gives nonsense. The pieces carry no numbers
// of their own — a twelfth of the bar is too narrow for one — so the two
// colours are named by the swatches beside the lines above the bar.
const SVG = "http://www.w3.org/2000/svg"
const LEFT = 20, WIDTH = 320, TOP = 34, HEIGHT = 46
// A line never ends on a lone sign: every =, ≈, ·, :, ÷, + or − that stands
// between spaces is tied to what follows it with a non-breaking space.
const tie = (text) => text.replace(/(?<=\s)([=≈·:÷+−]) /g, "$1\u00A0")

const gcd = (a, b) => (b ? gcd(b, a % b) : a)
// A fraction in lowest terms; a whole number is written without a bar.
const fraction = (top, bottom) => {
  const common = gcd(top, bottom)
  return bottom / common === 1 ? String(top / common) : `${top / common}/${bottom / common}`
}

// 1/6 + 1/3 = 1/6 + 2/6 = 3/6 = 1/2 — every step a pupil would write, and
// none that changes nothing.
function addRates(first, second) {
  const bottom = (first * second) / gcd(first, second)
  const a = bottom / first, b = bottom / second
  const steps = [`1/${first} + 1/${second}`]
  if (a > 1 || b > 1) steps.push(`${a}/${bottom} + ${b}/${bottom}`)
  steps.push(`${a + b}/${bottom}`)
  if (gcd(a + b, bottom) > 1) steps.push(fraction(a + b, bottom))
  const common = gcd(a + b, bottom)
  return { steps: steps.join(" = "), top: (a + b) / common, bottom: bottom / common }
}

export default class extends Controller {
  static targets = ["first", "second", "firstOut", "secondOut", "firstRate", "secondRate", "sum", "figure", "time", "note"]
  static values = { copy: Object }

  connect() {
    this.render()
  }

  render() {
    const copy = this.copyValue
    const first = Number(this.firstTarget.value)
    const second = Number(this.secondTarget.value)
    const rate = addRates(first, second)
    // The time together is the rate turned over: bottom/top hours.
    const hours = rate.bottom / rate.top
    const whole = Math.floor(rate.bottom / rate.top)
    const rest = rate.bottom % rate.top
    const rounded = Math.round(hours * 100) / 100
    const decimal = (Math.abs(rounded - hours) < 1e-9 ? "" : "≈\u00A0") + String(rounded).replace(".", copy.point)
    const mixed = rest === 0 ? String(whole) : `${whole}\u00A0${rest}/${rate.top}`

    const fill = (text) => tie(text)
      .replaceAll("%{first}", first).replaceAll("%{second}", second).replaceAll("%{total}", first + second)
      .replaceAll("%{steps}", tie(rate.steps)).replaceAll("%{rate}", fraction(rate.top, rate.bottom))
      .replaceAll("%{improper}", `${rate.bottom}/${rate.top}`).replaceAll("%{mixed}", mixed).replaceAll("%{decimal}", decimal)
      .replaceAll("%{faster}", Math.min(first, second)).replaceAll("%{product}", first * second)

    this.firstOutTarget.textContent = `${first} ${copy.h}`
    this.secondOutTarget.textContent = `${second} ${copy.h}`
    this.firstRateTarget.textContent = fill(copy.first_rate)
    this.secondRateTarget.textContent = fill(copy.second_rate)
    this.sumTarget.textContent = fill(copy.sum)
    this.timeTarget.textContent = fill(rest === 0 ? copy.time_whole : copy.time_mixed)
    this.noteTarget.textContent = fill(copy.note)
    this.figureTarget.replaceChildren(this.pool(first, second, hours, fill(copy.figure), fill(copy.full)))
  }

  // The pool as a bar: each hour adds the first tap's piece and then the
  // second's, and the last hour is cut where the pool is full.
  pool(first, second, hours, label, full) {
    const copy = this.copyValue
    const svg = this.node("svg", { viewBox: "0 0 360 112", class: "w-full max-w-[460px]", role: "img" })
    svg.setAttribute("aria-label", label)
    svg.append(this.node("rect", { x: LEFT, y: TOP, width: WIDTH, height: HEIGHT, fill: "#ececf4" }))

    const pieces = [
      { width: WIDTH / first, fill: "#5048e5" },
      { width: WIDTH / second, fill: "#a5aaff" }
    ]
    let x = LEFT
    for (let hour = 1; hour <= Math.ceil(hours - 1e-9); hour++) {
      // The part of this hour the taps still run for: all of it, or what is
      // left of the last one.
      const part = Math.min(1, hours - (hour - 1))
      for (const piece of pieces) {
        const width = piece.width * part
        svg.append(this.node("rect", { x, y: TOP, width, height: HEIGHT, fill: piece.fill, stroke: "#ffffff", "stroke-width": 1.5 }))
        x += width
      }
      if (part > 1 - 1e-9) {
        svg.append(this.node("line", { x1: x, y1: TOP + HEIGHT, x2: x, y2: TOP + HEIGHT + 8, stroke: "#50506b", "stroke-width": 2 }))
        svg.append(this.text(`${hour} ${copy.h}`, { x, y: TOP + HEIGHT + 24, "text-anchor": "middle", "font-size": 14, "font-weight": 900, fill: "#312e81" }))
      }
    }
    svg.append(this.node("rect", { x: LEFT, y: TOP, width: WIDTH, height: HEIGHT, fill: "none", stroke: "#312e81", "stroke-width": 2 }))
    // The moment the pool is full, written over its far end — whole hours
    // or not — with a tick down to the bar.
    svg.append(this.node("line", { x1: LEFT + WIDTH, y1: TOP - 8, x2: LEFT + WIDTH, y2: TOP, stroke: "#312e81", "stroke-width": 2 }))
    svg.append(this.text(full, { x: LEFT + WIDTH, y: TOP - 14, "text-anchor": "end", "font-size": 14, "font-weight": 900, fill: "#312e81" }))
    return svg
  }

  text(content, attributes) {
    const element = this.node("text", attributes)
    element.textContent = content
    return element
  }

  node(tag, attributes) {
    const element = document.createElementNS(SVG, tag)
    for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value)
    return element
  }
}
