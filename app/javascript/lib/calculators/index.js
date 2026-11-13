// The arithmetic and the figure of each calculator page, by the page's slug
// (config/calculators/<slug>.yml). A module exports one function per mode.
import triangle from "./triangle.js"
import { rectangle, parallelogram, trapezium, rhombus, circleArea } from "./plane.js"
import { cube, cuboid, prism, pyramid, cylinder, cone, sphere } from "./solids.js"

export default {
  "litse-na-triagalnik": triangle,
  "litse-na-pravoagalnik": rectangle,
  "litse-na-usporednik": parallelogram,
  "litse-na-trapets": trapezium,
  "litse-na-romb": rhombus,
  "litse-na-krag": circleArea,
  "kub": cube,
  "paralelepiped": cuboid,
  "prizma": prism,
  "piramida": pyramid,
  "tsilindar": cylinder,
  "konus": cone,
  "kalbo": sphere
}
