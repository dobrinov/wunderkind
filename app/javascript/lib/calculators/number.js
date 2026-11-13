// How a calculator writes a number it has rounded. The working is read by a
// child who may check it, so a rounded value never follows an equals sign:
// 1/3 of π is „≈ 0,33π", not „= 0,33π".

// True when the value is what its two-decimal rendering says it is.
export const exact = (value, digits = 2) => Math.abs(value * 10 ** digits - Math.round(value * 10 ** digits)) < 1e-9

export const eq = (value) => (exact(value) ? "=" : "≈")

// A multiple of π: „25π", and plain „π" rather than „1π".
export const pi = (coefficient, fmt) => (coefficient === 1 ? "π" : `${fmt(coefficient)}π`)
