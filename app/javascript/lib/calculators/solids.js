import { fit, face, line, dashed, label, middle, rim, scaleOf, GREY } from "./figure.js"
import { eq, pi } from "./number.js"

// The solids: cube, cuboid, prism, pyramid, cylinder, cone, sphere. Drawn in
// an oblique projection — the front face true to its numbers, depth going up
// and to the right at a fraction of its length — with the edges you could not
// see dashed, the way a textbook draws them.
const DEPTH = [0.42, 0.3]

// A box a wide, b deep, c tall, and the labels for its three edges.
function box(a, b, c, labels) {
  const [dx, dy] = [b * DEPTH[0], b * DEPTH[1]]
  const points = [[0, 0], [a, 0], [a, c], [0, c], [dx, dy], [a + dx, dy], [a + dx, c + dy], [dx, c + dy]]
  const place = fit(points)
  const [A, B, C, D, E, F, G, H] = points.map(place)

  return [
    face([A, B, C, D]), face([D, C, G, H], 0.6), face([B, F, G, C], 0.8),
    dashed(A, E), dashed(E, F), dashed(E, H),
    line(A, B), line(B, C), line(C, D), line(D, A),
    line(D, H), line(H, G), line(G, C), line(B, F), line(F, G),
    label(middle(A, B), labels[0], { dy: 26 }),
    label(middle(B, F), labels[1], { anchor: "start", dx: 10, dy: 14 }),
    label(middle(A, D), labels[2], { anchor: "end", dx: -10, dy: 5 })
  ].join("")
}

export const cube = {
  edge({ a }, { fmt, copy }) {
    return {
      steps: [`V = ${fmt(a)}³ = ${fmt(a)} · ${fmt(a)} · ${fmt(a)} = ${fmt(a ** 3)} ${copy.volume_unit}`, `S = 6 · ${fmt(a)}² = 6 · ${fmt(a * a)} = ${fmt(6 * a * a)} ${copy.area_unit}`],
      svg: box(a, a, a, [`a = ${fmt(a)}`, "", ""])
    }
  }
}

export const cuboid = {
  edges({ a, b, c }, { fmt, copy }) {
    return {
      steps: [
        `V = ${fmt(a)} · ${fmt(b)} · ${fmt(c)} = ${fmt(a * b * c)} ${copy.volume_unit}`,
        `S = 2 · (${fmt(a * b)} + ${fmt(b * c)} + ${fmt(c * a)}) = ${fmt(2 * (a * b + b * c + c * a))} ${copy.area_unit}`
      ],
      svg: box(a, b, c, [`a = ${fmt(a)}`, `b = ${fmt(b)}`, `c = ${fmt(c)}`])
    }
  }
}

export const prism = {
  // A right prism on a square base: the one a school problem most often
  // means by „правилна четириъгълна призма".
  square({ a, h }, { fmt, copy }) {
    return {
      steps: [
        `B = ${fmt(a)}² = ${fmt(a * a)} ${copy.area_unit}`,
        `V = B · h = ${fmt(a * a)} · ${fmt(h)} = ${fmt(a * a * h)} ${copy.volume_unit}`,
        `M = 4 · ${fmt(a)} · ${fmt(h)} = ${fmt(4 * a * h)} ${copy.area_unit}`,
        `S = 2B + M = ${fmt(2 * a * a + 4 * a * h)} ${copy.area_unit}`
      ],
      svg: box(a, a, h, [`a = ${fmt(a)}`, "", `h = ${fmt(h)}`])
    }
  },

  // Any prism, from the area of its base.
  base({ B, h }, { fmt, copy }) {
    const side = Math.sqrt(B)
    return {
      steps: [`V = B · h = ${fmt(B)} · ${fmt(h)} = ${fmt(B * h)} ${copy.volume_unit}`],
      readouts: { B: `${fmt(B)} ${copy.area_unit}` },
      svg: box(side, side, h, [`B = ${fmt(B)}`, "", `h = ${fmt(h)}`])
    }
  }
}

// A pyramid on a square base of side a (drawn as a parallelogram) with its
// apex h above the centre.
function pyramidFigure(a, h, labels) {
  const [dx, dy] = [a * DEPTH[0], a * DEPTH[1]]
  const centre = [(a + dx) / 2, dy / 2]
  const points = [[0, 0], [a, 0], [a + dx, dy], [dx, dy], [centre[0], centre[1] + h], centre]
  const place = fit(points)
  const [A, B, C, D, T, O] = points.map(place)

  return [
    face([A, B, T]), face([B, C, T], 0.7),
    dashed(C, D), dashed(D, A), dashed(D, T), dashed(T, O),
    line(A, B), line(B, C), line(A, T), line(B, T), line(C, T),
    label(middle(A, B), labels[0], { dy: 26 }),
    // Beside the middle of the height, on its left; the halo keeps it
    // readable over the edges that cross there.
    label(middle(T, O), labels[1], { anchor: "end", dx: -8, dy: 5, color: GREY })
  ].join("")
}

export const pyramid = {
  square({ a, h }, { fmt, copy }) {
    const k = Math.sqrt(h * h + (a * a) / 4)
    return {
      steps: [
        `B = ${fmt(a)}² = ${fmt(a * a)} ${copy.area_unit}`,
        `V = B · h / 3 = ${fmt(a * a)} · ${fmt(h)} / 3 ${eq((a * a * h) / 3)} ${fmt((a * a * h) / 3)} ${copy.volume_unit}`,
        `k = √(${fmt(h)}² + ${fmt(a / 2)}²) ${eq(k)} ${fmt(k)} ${copy.unit}`,
        `M = 4 · ${fmt(a)} · k / 2 ${eq(2 * a * k)} ${fmt(2 * a * k)} ${copy.area_unit}`
      ],
      svg: pyramidFigure(a, h, [`a = ${fmt(a)}`, `h = ${fmt(h)}`])
    }
  },

  base({ B, h }, { fmt, copy }) {
    return {
      steps: [`V = B · h / 3 = ${fmt(B)} · ${fmt(h)} / 3 ${eq((B * h) / 3)} ${fmt((B * h) / 3)} ${copy.volume_unit}`],
      readouts: { B: `${fmt(B)} ${copy.area_unit}` },
      svg: pyramidFigure(Math.sqrt(B), h, [`B = ${fmt(B)}`, `h = ${fmt(h)}`])
    }
  }
}

const FLAT = 0.3

export const cylinder = {
  radius({ r, h }, { fmt, copy }) {
    const place = fit([[-r, -r * FLAT], [r, h + r * FLAT]])
    const s = scaleOf(place)
    const [bottom, top] = [place([0, 0]), place([0, h])]
    const [BL, BR, TL, TR] = [[-r, 0], [r, 0], [-r, h], [r, h]].map(place)

    return {
      steps: [
        `V = π · ${fmt(r)}² · ${fmt(h)} = ${pi(r * r * h, fmt)} ≈ ${fmt(Math.PI * r * r * h)} ${copy.volume_unit}`,
        `S = 2π · ${fmt(r)} · (${fmt(r)} + ${fmt(h)}) = ${pi(2 * r * (r + h), fmt)} ≈ ${fmt(2 * Math.PI * r * (r + h))} ${copy.area_unit}`
      ],
      svg: [
        face([BL, BR, TR, TL]),
        rim(bottom, s * r, s * r * FLAT, { fill: true }),
        rim(top, s * r, s * r * FLAT, { open: true, fill: true }),
        line(BL, TL), line(BR, TR),
        dashed(bottom, BR),
        // Under the solid: on the base itself it sat on the rim.
        label([middle(bottom, BR)[0], bottom[1] + s * r * FLAT + 20], `r = ${fmt(r)}`, { color: GREY }),
        label(middle(BR, TR), `h = ${fmt(h)}`, { anchor: "start", dx: 10, dy: 5 })
      ].join("")
    }
  }
}

export const cone = {
  radius({ r, h }, { fmt, copy }) {
    const l = Math.sqrt(r * r + h * h)
    // The base is drawn flatter for a low cone, so the apex always stands
    // clear of it: with the usual flattening a cone of r 10, h 1 had its
    // apex inside its own base and read as a disc with a line across it.
    const flat = Math.min(r * FLAT, h * 0.4)
    const place = fit([[-r, -flat], [r, h]])
    const s = scaleOf(place)
    const [O, T, R] = [[0, 0], [0, h], [r, 0]].map(place)
    const [rx, ry, rise] = [s * r, s * flat, s * h]
    // The slant lines touch the base where a tangent from the apex does —
    // a little above the ends of its long axis — not at those ends, which
    // left the far half of the rim poking out past them.
    const [tx, ty] = [rx * Math.sqrt(1 - (ry / rise) ** 2), (ry * ry) / rise]
    const [TL, TR] = [[O[0] - tx, O[1] - ty], [O[0] + tx, O[1] - ty]]
    const volume = (r * r * h) / 3

    return {
      steps: [
        `V = π · ${fmt(r)}² · ${fmt(h)} / 3 ${eq(volume)} ${pi(volume, fmt)} ≈ ${fmt(Math.PI * volume)} ${copy.volume_unit}`,
        `l = √(${fmt(r)}² + ${fmt(h)}²) ${eq(l)} ${fmt(l)} ${copy.unit}`,
        `S = π · ${fmt(r)} · (${fmt(r)} + l) ${eq(r * (r + l))} ${pi(r * (r + l), fmt)} ≈ ${fmt(Math.PI * r * (r + l))} ${copy.area_unit}`
      ],
      svg: [
        face([TL, TR, T]),
        rim(O, rx, ry, { fill: true }),
        line(TL, T), line(TR, T),
        dashed(O, T), dashed(O, R),
        // Each label where nothing else is: r under the base, h left of the
        // height, l beside the upper slant.
        label([middle(O, R)[0], O[1] + ry + 20], `r = ${fmt(r)}`, { color: GREY }),
        label([O[0], O[1] - rise * 0.55], `h = ${fmt(h)}`, { anchor: "end", dx: -8, color: GREY }),
        label([T[0] + tx * 0.4, T[1] + (TR[1] - T[1]) * 0.4], `l`, { anchor: "start", dx: 12 })
      ].join("")
    }
  }
}

export const sphere = {
  radius({ r }, { fmt, copy }) {
    const place = fit([[-r, -r], [r, r]], { padTop: 20, padBottom: 20 })
    const s = scaleOf(place)
    const O = place([0, 0])
    const E = place([r, 0])

    return {
      steps: [
        `V = 4 · π · ${fmt(r)}³ / 3 ${eq((4 * r ** 3) / 3)} ${pi((4 * r ** 3) / 3, fmt)} ≈ ${fmt((4 * Math.PI * r ** 3) / 3)} ${copy.volume_unit}`,
        `S = 4 · π · ${fmt(r)}² = ${pi(4 * r * r, fmt)} ≈ ${fmt(4 * Math.PI * r * r)} ${copy.area_unit}`
      ],
      svg: [
        `<circle cx="${O[0].toFixed(1)}" cy="${O[1].toFixed(1)}" r="${(s * r).toFixed(1)}" fill="#e2e4ff" stroke="#5048e5" stroke-width="3"/>`,
        rim(O, s * r, s * r * FLAT),
        dashed(O, E),
        label(middle(O, E), `r = ${fmt(r)}`, { dy: -8, color: GREY })
      ].join("")
    }
  }
}
