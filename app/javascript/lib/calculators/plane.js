import { fit, polygon, dashed, label, rightAngle, middle, circle, dot, line, scaleOf, GREY } from "./figure.js"

// The plane figures after the triangle: rectangle and square, parallelogram,
// trapezium, rhombus, circle. Same contract as triangle.js — a function per
// mode, from the sliders' values to the working and the figure.

export const rectangle = {
  rect({ a, b }, { fmt, copy }) {
    const place = fit([[0, 0], [a, b]])
    const [A, B, C, D] = [[0, 0], [a, 0], [a, b], [0, b]].map(place)

    return {
      steps: [`S = ${fmt(a)} · ${fmt(b)} = ${fmt(a * b)} ${copy.area_unit}`, `P = 2 · (${fmt(a)} + ${fmt(b)}) = ${fmt(2 * (a + b))} ${copy.unit}`],
      svg: [
        polygon([A, B, C, D]),
        label(middle(A, B), `a = ${fmt(a)}`, { dy: 26 }),
        label(middle(B, C), `b = ${fmt(b)}`, { anchor: "start", dx: 10, dy: 5 })
      ].join("")
    }
  },

  square({ a }, { fmt, copy }) {
    const place = fit([[0, 0], [a, a]])
    const [A, B, C, D] = [[0, 0], [a, 0], [a, a], [0, a]].map(place)

    return {
      steps: [`S = ${fmt(a)}² = ${fmt(a)} · ${fmt(a)} = ${fmt(a * a)} ${copy.area_unit}`, `P = 4 · ${fmt(a)} = ${fmt(4 * a)} ${copy.unit}`],
      svg: [
        polygon([A, B, C, D]),
        label(middle(A, B), `a = ${fmt(a)}`, { dy: 26 }),
        label(middle(B, C), `a = ${fmt(a)}`, { anchor: "start", dx: 10, dy: 5 })
      ].join("")
    }
  }
}

export const parallelogram = {
  // `t` leans the figure: how far the top side is shifted, in percent of a.
  base({ a, h, t }, { fmt, copy }) {
    const shift = (a * t) / 100
    const corners = [[0, 0], [a, 0], [a + shift, h], [shift, h]]
    const place = fit(corners)
    const [A, B, C, D] = corners.map(place)
    const foot = place([shift, 0])

    return {
      steps: [`S = ${fmt(a)} · ${fmt(h)} = ${fmt(a * h)} ${copy.area_unit}`],
      readouts: { t: t === 0 ? copy.upright : copy.leaning },
      svg: [
        polygon([A, B, C, D]),
        t === 0 ? "" : dashed(D, foot),
        t === 0 ? "" : rightAngle(foot, [1, 0], [0, -1], 10),
        label(middle(A, B), `a = ${fmt(a)}`, { dy: 26 }),
        label(middle(D, foot), `hₐ = ${fmt(h)}`, { anchor: "start", dx: 10, dy: 5, color: GREY })
      ].join("")
    }
  }
}

export const trapezium = {
  // `t` slides the top base along: 0 puts it flush left, 100 flush right.
  bases({ a, b, h, t }, { fmt, copy }) {
    const left = ((a - b) * t) / 100
    const corners = [[0, 0], [a, 0], [left + b, h], [left, h]]
    const place = fit(corners)
    const [A, B, C, D] = corners.map(place)
    const foot = place([left, 0])

    return {
      steps: [`S = (${fmt(a)} + ${fmt(b)}) · ${fmt(h)} / 2`, `= ${fmt(a + b)} · ${fmt(h)} / 2 = ${fmt(((a + b) * h) / 2)} ${copy.area_unit}`],
      readouts: { t: a === b ? copy.parallelogram : t === 50 ? copy.isosceles : t === 0 || t === 100 ? copy.right_angled : copy.scalene },
      svg: [
        polygon([A, B, C, D]),
        dashed(D, foot),
        label(middle(A, B), `a = ${fmt(a)}`, { dy: 26 }),
        label(middle(D, C), `b = ${fmt(b)}`, { dy: -10 }),
        label(middle(D, foot), `h = ${fmt(h)}`, { anchor: "start", dx: 10, dy: 5, color: GREY })
      ].join("")
    }
  }
}

export const rhombus = {
  diagonals({ p, q }, { fmt, copy }) {
    const corners = [[-p / 2, 0], [0, -q / 2], [p / 2, 0], [0, q / 2]]
    const place = fit(corners)
    const [L, Bm, R, T] = corners.map(place)
    const side = Math.sqrt((p * p + q * q) / 4)

    return {
      steps: [`S = ${fmt(p)} · ${fmt(q)} / 2 = ${fmt((p * q) / 2)} ${copy.area_unit}`, `a = ${fmt(side)} ${copy.unit}`],
      svg: [
        polygon([L, Bm, R, T]),
        dashed(L, R),
        dashed(T, Bm),
        label(middle(L, R), `d₁ = ${fmt(p)}`, { dx: (R[0] - L[0]) / 4, dy: -8, color: GREY }),
        label(middle(T, Bm), `d₂ = ${fmt(q)}`, { anchor: "start", dx: 8, dy: (Bm[1] - T[1]) / 4, color: GREY })
      ].join("")
    }
  },

  // A rhombus is a parallelogram, so side · height works too. The height
  // cannot be longer than the side.
  height({ a, h }, { fmt, copy }) {
    if (h > a) return { steps: [copy.impossible], invalid: true, svg: "" }

    const shift = Math.sqrt(a * a - h * h)
    const corners = [[0, 0], [a, 0], [a + shift, h], [shift, h]]
    const place = fit(corners)
    const [A, B, C, D] = corners.map(place)
    const foot = place([shift, 0])

    return {
      steps: [`S = ${fmt(a)} · ${fmt(h)} = ${fmt(a * h)} ${copy.area_unit}`],
      svg: [
        polygon([A, B, C, D]),
        h === a ? "" : dashed(D, foot),
        label(middle(A, B), `a = ${fmt(a)}`, { dy: 26 }),
        label(middle(D, foot), `h = ${fmt(h)}`, { anchor: "start", dx: 10, dy: 5, color: GREY })
      ].join("")
    }
  }
}

const disc = (r, fmt, mark) => {
  const place = fit([[-r, -r], [r, r]], { padTop: 20, padBottom: 20 })
  const O = place([0, 0])
  const E = place([r, 0])
  const W = place([-r, 0])
  return [
    circle(O, scaleOf(place) * r),
    mark === "d" ? line(W, E, { width: 2.5 }) : line(O, E, { width: 2.5 }),
    dot(O),
    mark === "d" ? label(O, `d = ${fmt(2 * r)}`, { dy: -10 }) : label(middle(O, E), `r = ${fmt(r)}`, { dy: -10 })
  ].join("")
}

export const circleArea = {
  radius({ r }, { fmt, copy }) {
    return {
      steps: [
        `S = π · ${fmt(r)}² = ${fmt(r * r)}π ≈ ${fmt(Math.PI * r * r)} ${copy.area_unit}`,
        `C = 2 · π · ${fmt(r)} = ${fmt(2 * r)}π ≈ ${fmt(2 * Math.PI * r)} ${copy.unit}`
      ],
      svg: disc(r, fmt, "r")
    }
  },

  diameter({ d }, { fmt, copy }) {
    const r = d / 2
    return {
      steps: [
        `r = ${fmt(d)} / 2 = ${fmt(r)} ${copy.unit}`,
        `S = π · ${fmt(r)}² = ${fmt(r * r)}π ≈ ${fmt(Math.PI * r * r)} ${copy.area_unit}`,
        `C = π · ${fmt(d)} = ${fmt(d)}π ≈ ${fmt(Math.PI * d)} ${copy.unit}`
      ],
      svg: disc(r, fmt, "d")
    }
  }
}
