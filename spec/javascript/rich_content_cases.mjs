// Runs spec/fixtures/rich_content_cases.json through app/javascript/lib/authoring.js
// and prints the cases it parses differently from the server, as JSON — an
// empty list is a pass. Called by spec/services/rich_content_spec.rb.
//
// The module is loaded from a data: URL so that node reads it as ESM whatever
// its version and whatever package.json says about module types.
import fs from "node:fs"

const [libPath, fixturePath] = process.argv.slice(2)
const source = fs.readFileSync(libPath, "utf8")
const { parseAuthoring } = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`)

// Key order is not part of a document, so both sides are written out sorted.
const canonical = (value) =>
  Array.isArray(value) ? value.map(canonical)
    : value && typeof value === "object"
      ? Object.fromEntries(Object.keys(value).sort().map((key) => [ key, canonical(value[key]) ]))
      : value

const failures = []
for (const testCase of JSON.parse(fs.readFileSync(fixturePath, "utf8"))) {
  const actual = parseAuthoring(testCase.text, { latex: testCase.latex })
  if (JSON.stringify(canonical(actual)) !== JSON.stringify(canonical(testCase.doc))) {
    failures.push({ note: testCase.note, text: testCase.text, expected: testCase.doc, actual })
  }
}
process.stdout.write(JSON.stringify(failures))
