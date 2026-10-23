# Widget ideas from the klasirane.com archive

What Bulgarian exam and competition papers ask children to *do*, read for
interaction formats that a widget could carry. Inspiration only: no problem
text from these papers goes into the bank. The examples below are short
paraphrases with their source, so the original can be looked up. The papers
belong to their authors, and the corpus keeps the rule it already applies to
Khan Academy BG and IXL (read for coverage, never copied).

## What was read

klasirane.com is a React app over a small API: `GET /api/home/competitions.txt`
lists the competitions, `GET /api/competitions/{code}/alldata` gives a
season → year → grade index, and the problems are PDFs at
`/api/competitions/{code}/{season}/{year}/{grade}/probs`. 128 papers, 380
pages, rendered to images and read page by page (the figures carry most of the
content; 8 papers are scans with no text layer at all):

| Competition | Papers | Years | Grades |
|---|---|---|---|
| НВО 4 / НВО 7 | 19 | 2016–2025 | 4, 7 |
| Европейско кенгуру (regional + national) | 24 | 2019–2025 | 3–8 |
| Турнир „Иван Салабашев“ | 20 | 2019–2025 | 3–7 |
| Турнир „Черноризец Храбър“ | 8 | 2019–2024 | 3–8 |
| Великденско математическо състезание | 20 | 2019–2025 | 3–7 |
| Пролетни математически състезания | 16 | 2019–2025 | 4–7 |
| Турнир „Ключът към знанието“ | 20 | 2024–2025 | 3–7 |
| Питагор | 1 | 2019 | 4 |

Sources below are written `competition year · grade · problem`. Counts are
problems of that format across the papers read, so they show how common it is,
not how many we could write.

## The headline for the geometry gaps

- **Circles barely exist at these grades.** Nine years of НВО 4 and НВО 7 and
  every competition read have no inscribed angle, central angle, tangent or
  arc problem. Circles appear only as areas built from quarter and half discs,
  points around a circle, radius and diameter, and pie charts. Teaching
  inscribed angles needs 8th-grade and olympiad material that this sample does
  not reach (СМБ tournaments, Минко Балкански, НОМ).
- **Congruence and bisectors are НВО 7 material, and there is plenty of it.**
  Perpendicular and angle bisectors appear in nearly every НВО 7 paper, almost
  always as "notice that these two segments are equal".
- **Transformations, folding and nets are Kangaroo material.** Folding,
  mirrors, rotations, cube nets and views are the commonest geometry formats
  there, and they barely appear anywhere else.

## The formats (geometry first)

Overlap is noted against the widgets already shipped (`geoboard`,
`angle_dial`, …) and the designed ones (EqualAngles, Evaluator, FactorTree, the
day wheel).

### 1. Tap the equal parts: perpendicular and angle bisectors (~20)
- **Example:** НВО 7 2017 · 7 · P12. In a triangle with AC = 5 cm and
  BC = 4 cm, the perpendicular bisector of AB meets AC at M; find the perimeter
  of BCM. The trick is noticing MB = MA, so the perimeter is AC + BC.
  Same idea: НВО 7 2017 P11 and P13, 2020 P15–16, 2024 P13–14, 2025 P11–12;
  ВМС 2019 · 7 · #17 (two bisectors cut AB into three equal parts).
- **Interaction:** the bisector is drawn dashed. The child taps every segment
  that must equal the highlighted one (MB → MA), or every angle equal to a
  given one (the halves of a bisected angle, base angles), then types the
  number the problem asks for.
- **Grading:** the set of tapped segment or angle ids (masked) against the set
  the construction makes equal, plus the number.
- **Must not:** draw the figure to scale (equal segments would *look* equal), or
  add tick marks when a segment is tapped. Authoring should distort the
  drawing and add near-equal decoys.
- **Overlap:** the same widget as **EqualAngles**, with segments added. Build
  one "tap the equal parts" widget with two modes, not two widgets.

### 2. Congruent triangles: match the corners, then find the pairs (~10)
- **Example:** НВО 7 2023 · 7 · P16. Two overlapping triangles are stated to be
  congruent, ΔABC ≅ ΔPMT; with some angles marked, find an angle of the second.
  ВМС 2025 · 7 · #14: in an isosceles triangle with points on its sides,
  count the pairs of congruent triangles. Also НВО 7 2020 P14, 2021 P10,
  2024 P11.
- **Interaction:**
  - Correspondence mode: drag from each corner of the first triangle to its
    partner in the second (lines appear between them), then tap the element
    asked for.
  - Pair-finding mode: tap three corners, then three more, to record a
    congruent pair in order.
- **Grading:** the corner mapping (masked like `matcher`) and the element id.
  In pair mode, the set of pairs, each checked as a valid correspondence.
- **Must not:** carry the markings across once the corners are matched (that
  answers step 2), or show "n pairs left to find".
- **Overlap:** `matcher` drawn on a figure. Nothing current covers
  congruence.

### 3. Draw a congruent copy on the grid (~7)
- **Example:** НВО 7 2016 · 7 · P12: choose three lattice points that make a
  triangle congruent to the drawn ABC. Also НВО 7 2016 P20 (an isosceles right
  triangle with legs adding to 14) and the point reflections in 2020 P18,
  2023 P20, 2025 P10.
- **Interaction:** draw the copy on pegs anywhere and in any orientation, or
  place the images of three corners after a reflection in an axis or the
  origin.
- **Grading:** congruence by the sorted squared side lengths, so any
  translated, rotated or flipped copy passes. Reflections compare the placed
  point set.
- **Overlap:** a `congruent_to` rule for **geoboard** (it already grades by
  shape and area) and a reflection mode for `coordinate_plot`. The cheapest
  item on this list.

### 4. Split a shape into congruent pieces (~6)
- **Example:** Кенгуру 2025 · 6 · P24: cut a 15-cell figure into five
  congruent pieces; which letter shares a piece with the star? Кенгуру
  2025 · 5 · P3: in how many of the five squares are the four parts congruent?
  Also 2024 · 3 · P1 and 2025 · 4 · P25.
- **Interaction:** colour grid cells in k colours, one colour per piece, or
  draw cuts along grid lines.
- **Grading:** by rule, with no stored answer: k pieces, each connected, all
  congruent once rotations and reflections are normalised, plus any condition
  on a marked cell.
- **Must not:** show "these two match" while painting.
- **Overlap:** `grid_shade` for the painting. The congruence rule is new, and
  it is the hands-on form of congruence a 4th-grader can do.

### 5. Fold and punch (~14, the commonest Kangaroo geometry format)
- **Example:** Кенгуру 2022 · 4 · P14: a numbered 6×6 sheet is folded twice
  and punched once; which numbers have a hole? Also 2025 · 5 · P5 (a strip
  folded in three over holes), 2022 · 6 · P12 (a transparent square folded
  twice), snowflake cuts in 2024 · 5 · P24.
- **Interaction:** the folds are shown as lines on the open sheet and the
  punch on the folded one; the child shades every cell that ends up holed.
- **Grading:** the exact cell set, computed by reflecting the hole back
  through each fold.
- **Must not:** animate the unfolding. That animation is the answer.
- **Overlap:** `grid_shade` in exact-cells mode with a fold overlay; the
  reflection grader is new. It is the most-used case of the "transformations
  on a grid" sketch.

### 6. Mirror image, or seen from the other side (~10)
- **Example:** Кенгуру 2025 · 3 · P8: what "2025" looks like in a mirror; and
  2025 · 4 · P10, the difference between the mirrored number and 2025. Also
  2019 · 3 · P20 (woven strips seen from outside the window, where the
  over-and-under order flips too), 2024 · 3 · P12 (a two-coloured square on
  the window).
- **Interaction:** a mirror line and a pattern on a grid; the child paints its
  image on the other side.
- **Grading:** the exact reflected cell set.
- **Must not:** draw the reflection live.
- **Overlap:** shares the reflection grader with #5. The strip variant needs
  layer order, which `grid_shade` can't express.

### 7. Turn it to the right pose: rotation (~10)
- **Example:** Кенгуру 2022 · 4 · P20: hexagon tiles may be turned; which ones,
  placed in the middle, connect house A to B and C but not D? Also
  2024 · 6 · P6 (two heptagons turning in opposite directions, what is opposite
  a given letter later), 2025 · 5 · P7 (a patterned hexagon rolled eight
  times), 2022 · 3 · P5 (the odd one out among rotated copies).
- **Interaction:** turn a copy in fixed steps (60°, a seventh of a turn), and
  flip it where the problem allows.
- **Grading:** the rotation index mod n plus a flip bit, or for path tiles, a
  rule that the connections hold.
- **Must not:** show the target pose beside the copy, or the child matches by
  eye. Show the start and the rule only.
- **Overlap:** `angle_dial` and `unit_circle` mechanically, but rotating a
  pattern is new.

### 8. Points on a circle: chords and inscribed triangles (~6)
- **Example:** ВМС 2022 · 3 · #4: triangles drawn with corners on points around
  a circle; how many are acute? Черноризец Храбър 2022 · 7–8 · #20: which
  triangle with corners on a regular 15-gon has the largest area? Also
  Кенгуру 2019 · 7 · P16 (numbers round a circle, two of them at the ends of a
  diameter, how many numbers are there).
- **Interaction:** N equally spaced pegs on a circle; the child taps three to
  draw a triangle that meets a condition (right-angled, obtuse, containing the
  centre), taps two for a chord or diameter, or collects all chords shorter
  than the radius.
- **Grading:** from the peg indices by rule (an inscribed angle is half its
  arc), so any valid triangle passes; or, for "find them all", the full set.
- **Must not:** show angle or arc measures live.
- **Overlap:** a circular-peg mode of **geoboard**, using the circle of
  `unit_circle`. It is the only route into inscribed angles and Thales that
  these grades offer, so it is the place to start the circle gap.

### 9. Shaded area from circle parts (~8)
- **Example:** Ключът към знанието 2025 · 6 · #19: the shaded part of a square
  holding a circle and a quarter circle. Also the same paper #3 (a lens made of
  two quarter circles), ВМС 2019 · 6 · #11 (a semicircle on a grid),
  ВМС 2024 · 4 · #11 (arc length round three circles).
- **Interaction:** build the shaded region as a signed sum of stock pieces
  (square, quarter disc, half disc, triangle), each with a count and a sign.
- **Grading:** the server reduces the sum to a + bπ and compares it, so any
  correct decomposition passes.
- **Must not:** draw the resulting region live, or it becomes matching a
  picture by trial and error.
- **Overlap:** the "area splitter" sketch, extended to circle parts.

### 10. Nets with something on the faces: dice and patterns (~14)
- **Example:** Кенгуру 2019 · 5 · P18: a cube net carries a drawn line; which net
  folds into a cube whose line is one closed loop? ВМС 2022 · 6 · #15: four
  dice in a row, opposite faces sum to 7 and touching faces to 8; find a
  hidden face. Also Кенгуру 2024 · 3 · P21 (a die rolled along a path, what is
  on top), Питагор 2019 · 4 · #4 (a pyramid net).
- **Interaction:** fill or turn the faces of a net, or of isometric dice, so
  the folded cube satisfies the rule.
- **Grading:** fold the net server-side to get which faces meet along which
  edges, then check the rule.
- **Must not:** show a 3D preview for "what is on top" questions.
- **Overlap:** the "cube net" sketch, with face content and orientation added.

### 11. Views and stack heights (~20)
- **Example:** Кенгуру 2022 · 5 · P25: from the top, front and side views, what
  is the largest number of cubes? Кенгуру 2022 · 4 · P16: how many white blocks
  build the shown solid. Also Салабашев 2025 · 7 · #5 (a painted box cut into
  unit cubes), Ключът 2024 · 6 · #17.
- **Interaction:** a top-view grid; the child taps each cell to set its stack
  height.
- **Grading:** by rule: compute the views from the heights, compare them with
  the given views, and check the count condition (largest or smallest).
- **Must not:** render the stack in 3D for "what does it look like from the
  front".
- **Overlap:** the "building with cubes" sketch; this is its grader.

### 12. Find every figure in the drawing (~25)
- **Example:** НВО 4 has one or two of these in every year: 2016 P13 (acute
  angles in a hexagon cut by diagonals), 2019 P14 (triangles), 2022 P12
  (isosceles triangles). Also Салабашев 2019 · 4 · #11 (rectangles on a 4×4
  grid holding exactly one heart), Ключът 2024 · 3 · #10.
- **Interaction:** the drawing is points and segments; the child taps corners
  to outline each figure found. Each is coloured and listed; a figure that
  doesn't close is ignored.
- **Grading:** the set of found figures (sorted corner ids) against the full
  set, enumerated at build time. Missing or extra fails.
- **Must not:** show "found 3 of 7" or "all found". That makes it impossible
  to get wrong.
- **Overlap:** EqualAngles' tapping, but nothing current enumerates. It turns
  a three-option НВО 4 count, which can be guessed, into real work.

### 13. Write the values on the figure (~45, the most common format overall)
- **Example:** НВО 7 2017 · 7 · P10: parallels a and b cut by c, one angle 140°,
  another written 2x; find x. ВМС 2022 · 7 · #20: five statements about one
  triangle with an altitude and a perpendicular bisector, each completed with
  a number. For lengths: Ключът 2025 · 4 · #13 (a rectangle made of four
  rectangles, three areas given).
- **Interaction:** number boxes sit on the figure at an angle's arc or beside
  a side; the child fills in the intermediate values, not only the final one,
  optionally choosing a reason for each (vertical, supplementary,
  corresponding, angle sum).
- **Grading:** `ExactValue` per box; the target is required and the other
  boxes are checked when filled.
- **Must not:** fill in neighbouring values itself.
- **Overlap:** `blanks` positioned on the figure, sharing the figure renderer
  with #1. Not a new kind of answer, but it shows a parent the whole chase
  instead of one number.

### 14. Numbers on the nodes of a figure (~30, the commonest Kangaroo format)
- **Example:** Кенгуру 2024 · 4 · P14: digits on the circles of a figure so that
  every line has the same sum. Черноризец Храбър 2019 · 3–4 · #6: swap two
  numbers so that every circle of a three-circle Venn sums to 19. Also
  Кенгуру 2025 · 4 · P26 (a magic six-pointed star), 2024 · 5 · P14 (a ring
  where neighbours differ by 1), Салабашев 2025 · 6 · #10 (an addition
  pyramid).
- **Interaction:** drag digit cards, each used once, onto nodes laid out
  anywhere on the figure.
- **Grading:** by the constraint (sums, products, differences), so every valid
  filling passes; optimisation versions also compare the objective with the
  known best, which `lib/uniqueness.rb` can confirm.
- **Must not:** total the lines live.
- **Overlap:** the "digit cards" sketch and `grid_fill`; the free layout and
  constraint grading are new.

### 15. Place the pieces: polyomino tiling (~16)
- **Example:** Кенгуру 2024 · 6 · P12: cover a numbered 4×4 board with four
  pieces so that a target number lands on the black square. Also Кенгуру
  2025 · 4–6 · P14–15 (fill the white cells), Ключът 2025 · 4 · #2 (pack 4×5
  tiles onto an n×20 board).
- **Interaction:** drag pieces onto a grid, tap to rotate, flip where allowed.
- **Grading:** by rule from each piece's position and orientation: no overlap,
  every target cell covered, plus the extra condition.
- **Must not:** snap pieces only to legal spots. If each piece has one legal
  place, the widget solves the puzzle; accept any placement and grade at the
  end.
- **Overlap:** none built. `lib/tiling.rb` already solves these for the checks.

## Also seen, not ranked

- **Trace the boundary** (~15, Салабашев): the perimeter of squares glued
  together. Tap every outer edge, then type the total; it overlaps `geoboard`'s
  perimeter rule.
- **Cryptarithms** (~16): the same letter is the same digit; it overlaps the
  digit-cards sketch and `column_arithmetic`.
- **Pie charts** (НВО 7 2019 P20, ВМС 2025 · 7 · #17): drag the sector
  dividers. The chart-builder sketch; show degrees while dragging, never the
  percentage or count per sector.
- **Arrow programs on a grid** (~6, Кенгуру 2022 · 3 · P1): build a move
  sequence, graded by simulation.
- **Paths on a graph** (~8, Салабашев 2025 · 5 · #10): cheapest route or
  labelling; never show a running total.
- **Hexagon minesweeper** (four consecutive 2024 Kangaroo papers, P24–26) and
  **map colouring**.
- **Pouring jugs** (Салабашев 2025 · 6 · #11): a simulation with the fewest
  pours as the goal.

## Where the designed widgets stand

- **EqualAngles** is confirmed and should grow into #1 ("tap the equal
  parts").
- **Geoboard** gains three modes from this list: congruent copy (#3),
  circular pegs (#8) and boundary tracing.
- **Angle dial** is enough for the angle problems themselves; what the papers
  add is the figure around it (#13).
- **Day wheel** generalises into #8's circle of points (passing a ball round
  a circle, Кенгуру 2024 · 3 · P4).
- **Evaluator** has one direct match: a table of simplification steps,
  НВО 7 2016 P17.
- **FactorTree** has no match in these papers; it stays justified by the bank
  itself.

## Suggested order

1. **#1 tap the equal parts** (EqualAngles extended): the bisector and
   congruence gap, and the most frequent НВО 7 geometry.
2. **#3 congruent copy on the geoboard:** a new rule for a shipped widget.
3. **#5 and #6 fold and mirror:** one reflection grader for both.
4. **#12 find every figure:** in every НВО 4 paper.
5. **#8 points on a circle:** the only way into the circle gap at these grades.
