import { fit, polygon, dashed, label, rightAngle, middle } from "./figure"

// „Лице на триъгълник": by a base and its height (with an apex that slides,
// to show the area does not care where it is), by the legs of a right
// triangle, and by three sides (Heron). Each mode takes the sliders' values
// and returns the working as lines of text, the figure, and what a slider's
// readout should say when it is not just its number.
export default {
  base({ a, h, t }, { fmt, copy }) {
    const apex = (a * t) / 100
    const place = fit([[0, 0], [a, 0], [apex, h]])
    const [A, B, C] = [[0, 0], [a, 0], [apex, h]].map(place)
    const foot = place([apex, 0])
    const kind = t === 0 || t === 100 ? copy.right_angled : t < 0 || t > 100 ? copy.obtuse : copy.acute

    return {
      steps: [`S = ${fmt(a)} · ${fmt(h)} / 2`, `= ${fmt(a * h)} / 2 = ${fmt((a * h) / 2)} ${copy.area_unit}`],
      readouts: { t: kind },
      svg: [
        polygon([A, B, C]),
        // The height, and the base carried on to meet it when the apex hangs
        // past an end of the base.
        apex < 0 ? dashed(foot, A) : apex > a ? dashed(B, foot) : "",
        dashed(C, foot),
        rightAngle(foot, [apex > a / 2 ? -1 : 1, 0], [0, -1], 10),
        label(middle(A, B), `a = ${fmt(a)}`, { dy: 26 }),
        // Beside the height, clear of the sides: outside the triangle when
        // the height falls outside it, else on the wider half.
        label(middle(C, foot), `hₐ = ${fmt(h)}`, apex >= a || (apex > 0 && apex <= a / 2)
          ? { anchor: "start", dx: 10, dy: 5, color: "#50506b" }
          : { anchor: "end", dx: -10, dy: 5, color: "#50506b" })
      ].join("")
    }
  },

  right({ a, b }, { fmt, copy }) {
    const place = fit([[0, 0], [a, 0], [0, b]])
    const [A, B, C] = [[0, 0], [a, 0], [0, b]].map(place)

    return {
      steps: [`S = ${fmt(a)} · ${fmt(b)} / 2`, `= ${fmt(a * b)} / 2 = ${fmt((a * b) / 2)} ${copy.area_unit}`],
      svg: [
        polygon([A, B, C]),
        rightAngle(A, [1, 0], [0, -1]),
        label(middle(A, B), `a = ${fmt(a)}`, { dy: 26 }),
        label(middle(A, C), `b = ${fmt(b)}`, { anchor: "end", dx: -10, dy: 5 }),
        label(middle(B, C), `c = ${fmt(Math.sqrt(a * a + b * b))}`, { anchor: "start", dx: 10, dy: -4, color: "#50506b" })
      ].join("")
    }
  },

  heron({ a, b, c }, { fmt, copy }) {
    if (a + b <= c || a + c <= b || b + c <= a) return { steps: [copy.impossible], invalid: true, svg: "" }

    const p = (a + b + c) / 2
    const product = p * (p - a) * (p - b) * (p - c)
    // c along the bottom, a opposite the left corner, b opposite the right.
    const x = (b * b + c * c - a * a) / (2 * c)
    const y = Math.sqrt(Math.max(0, b * b - x * x))
    const place = fit([[0, 0], [c, 0], [x, y]])
    const [A, B, C] = [[0, 0], [c, 0], [x, y]].map(place)

    return {
      steps: [
        `p = (${fmt(a)} + ${fmt(b)} + ${fmt(c)}) / 2 = ${fmt(p)}`,
        `S = √(${fmt(p)} · ${fmt(p - a)} · ${fmt(p - b)} · ${fmt(p - c)})`,
        `= √${fmt(product)} ${Number.isInteger(Math.sqrt(product)) ? "=" : "≈"} ${fmt(Math.sqrt(product))} ${copy.area_unit}`
      ],
      svg: [
        polygon([A, B, C]),
        label(middle(A, B), `c = ${fmt(c)}`, { dy: 26 }),
        label(middle(A, C), `b = ${fmt(b)}`, { anchor: "end", dx: -10, dy: 0 }),
        label(middle(B, C), `a = ${fmt(a)}`, { anchor: "start", dx: 10, dy: 0 })
      ].join("")
    }
  }
}
