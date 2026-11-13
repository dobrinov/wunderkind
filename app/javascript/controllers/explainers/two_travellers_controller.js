import { Controller } from "@hotwired/stimulus"

// „Задачи за движение": two travellers, A and B, on one straight road. Either
// they start at its two ends and move towards each other, or A starts behind
// B and chases. The time slider moves them in whole hours and stops them
// where they meet, so the reader watches the gap shrink by the same amount
// every hour — the sum of the speeds in one case, their difference in the
// other — which is the whole of t = s : (v₁ ± v₂). The road is rescaled to
// whatever the case needs, so the meeting point is always on it. The board is
// only 360 units wide so that its text is still readable on a phone.
const SVG = "http://www.w3.org/2000/svg"
const LEFT = 30, RIGHT = 330, ROAD = 64
// The most steps the time slider is given; a long chase moves in bigger steps.
const STEPS = 12
// How many hours the time slider offers when A never catches B.
const HOURS_WITHOUT_MEETING = 10

const round = (value) => Math.round(value * 100) / 100
const exact = (value) => Math.abs(round(value) - value) < 1e-9
// A line never ends on a lone sign: every =, ≈, ·, :, ÷, + or − that stands
// between spaces is tied to what follows it with a non-breaking space.
const tie = (text) => text.replace(/(?<=\s)([=≈·:÷+−]) /g, "$1\u00A0")

export default class extends Controller {
  static targets = ["mode", "v1", "v2", "distance", "time", "v1Out", "v2Out", "distanceOut", "timeOut", "setup", "figure", "now", "rate", "meet"]
  static values = { copy: Object }

  connect() {
    this.mode = "towards"
    this.render()
  }

  choose(event) {
    this.mode = event.params.mode
    this.modeTargets.forEach((button) => button.setAttribute("aria-pressed", button === event.currentTarget))
    this.render()
  }

  render() {
    const copy = this.copyValue
    const chase = this.mode === "chase"
    const v1 = Number(this.v1Target.value)
    const v2 = Number(this.v2Target.value)
    const s = Number(this.distanceTarget.value)
    // How much the gap closes in an hour; zero or less means it never does.
    const closing = chase ? v1 - v2 : v1 + v2
    const meets = closing > 0
    const meeting = meets ? s / closing : null

    // The slider moves in whole hours — in steps of several when the chase is
    // long — and its last position is the moment of the meeting itself, so
    // the time it shows is always the time of the picture.
    const step = meets ? Math.max(1, Math.ceil(meeting / STEPS - 1e-9)) : 1
    const positions = meets ? Math.max(1, Math.ceil(meeting / step - 1e-9)) : HOURS_WITHOUT_MEETING
    this.timeTarget.max = positions
    if (Number(this.timeTarget.value) > positions) this.timeTarget.value = positions
    const slider = Number(this.timeTarget.value) * step
    const met = meets && slider >= meeting - 1e-9
    const t = met ? meeting : slider

    const a = v1 * t
    const b = v2 * t
    const gap = met ? 0 : chase ? s + b - a : s - a - b
    // The road is as long as the case needs: the distance itself, or as far
    // as A has to go to catch B, or as far as B gets while A falls behind.
    const length = !chase ? s : meets ? v1 * meeting : s + v2 * HOURS_WITHOUT_MEETING
    const state = { a, b: chase ? s + b : s - b, startB: s, gap, met, length }

    // "3" when exact, "≈ 2,31" when rounded; `equals` puts the sign where
    // the equals sign would be, never after it.
    const num = (value) => String(round(value)).replace(".", copy.point)
    const about = (value) => (exact(value) ? "" : "≈\u00A0") + num(value)
    const equals = (value) => (exact(value) ? "=\u00A0" : "≈\u00A0") + num(value)
    const fill = (text, time = about(t)) => tie(text)
      .replaceAll("%{v1}", v1).replaceAll("%{v2}", v2).replaceAll("%{s}", s)
      .replaceAll("%{closing}", Math.abs(closing)).replaceAll("%{t}", time)
      .replaceAll("%{a}", about(a)).replaceAll("%{b}", about(b)).replaceAll("%{gap}", about(gap))

    this.v1OutTarget.textContent = `${v1} ${copy.kmh}`
    this.v2OutTarget.textContent = `${v2} ${copy.kmh}`
    this.distanceOutTarget.textContent = `${s} ${copy.km}`
    this.timeOutTarget.textContent = `${about(t)} ${copy.h}`
    this.setupTarget.textContent = fill(chase ? copy.setup_chase : copy.setup_towards)

    this.nowTarget.textContent = fill(
      met ? (chase ? copy.met_chase : copy.met_towards) : slider === 0 ? copy.now_start : copy.now
    )
    this.rateTarget.textContent = fill(
      !chase ? copy.rate_towards : closing > 0 ? copy.rate_chase : closing === 0 ? copy.rate_equal : copy.rate_slower
    )
    this.meetTarget.textContent = meets
      ? fill(chase ? copy.meet_chase : copy.meet_towards, equals(meeting))
      : copy.meet_never

    const gapLabel = met ? copy.met_label : fill(copy.gap_label)
    const lengthLabel = `${about(length)} ${copy.km}`
    this.figureTarget.replaceChildren(this.road(state, fill(copy.figure), gapLabel, `0 ${copy.km}`, lengthLabel))
  }

  road(state, label, gapLabel, zeroLabel, lengthLabel) {
    const px = (position) => LEFT + (position / state.length) * (RIGHT - LEFT)
    const svg = this.node("svg", { viewBox: "0 0 360 152", class: "w-full max-w-[460px]", role: "img" })
    svg.setAttribute("aria-label", label)

    svg.append(this.node("line", { x1: LEFT, y1: ROAD, x2: RIGHT, y2: ROAD, stroke: "#c5c5d6", "stroke-width": 6, "stroke-linecap": "round" }))
    // Where each of them started, and the way each has come since.
    for (const start of [0, state.startB]) {
      svg.append(this.node("line", { x1: px(start), y1: ROAD - 14, x2: px(start), y2: ROAD + 14, stroke: "#9a9ab0", "stroke-width": 2 }))
    }
    svg.append(this.node("line", { x1: px(state.startB), y1: ROAD, x2: px(state.b), y2: ROAD, stroke: "#a5aaff", "stroke-width": 6, "stroke-linecap": "round" }))
    svg.append(this.node("line", { x1: px(0), y1: ROAD, x2: px(state.a), y2: ROAD, stroke: "#5048e5", "stroke-width": 6, "stroke-linecap": "round" }))

    svg.append(this.node("circle", { cx: px(state.b), cy: ROAD, r: 10, fill: "#312e81", stroke: "#ffffff", "stroke-width": 2 }))
    svg.append(this.node("circle", { cx: px(state.a), cy: ROAD, r: 10, fill: "#5048e5", stroke: "#ffffff", "stroke-width": 2 }))
    // A is named above the road and B below it, so the two letters never
    // collide — not even when the travellers meet.
    svg.append(this.text("A", { x: px(state.a), y: ROAD - 20, "text-anchor": "middle", "font-size": 16, "font-weight": 900, fill: "#5048e5" }))
    svg.append(this.text("B", { x: px(state.b), y: ROAD + 32, "text-anchor": "middle", "font-size": 16, "font-weight": 900, fill: "#312e81" }))

    // The gap, written under its middle and kept on the board.
    const middle = Math.max(52, Math.min(308, (px(state.a) + px(state.b)) / 2))
    svg.append(this.text(gapLabel, { x: middle, y: ROAD + 54, "text-anchor": "middle", "font-size": 14, "font-weight": 900, fill: "#312e81" }))
    svg.append(this.text(zeroLabel, { x: LEFT, y: ROAD + 78, "text-anchor": "start", "font-size": 14, "font-weight": 800, fill: "#50506b" }))
    svg.append(this.text(lengthLabel, { x: RIGHT, y: ROAD + 78, "text-anchor": "end", "font-size": 14, "font-weight": 800, fill: "#50506b" }))
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
