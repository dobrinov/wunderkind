# Посочи равните части: a figure, one segment or angle highlighted, and the
# student taps every part the construction makes equal to it.
#
# The whole skill is noticing an equality the figure does not show: MB = MA
# because M is on the perpendicular bisector of AB, the halves of a bisected
# angle, the angles a transversal makes equal. So the equalities here come from
# the construction and never from measuring the drawing — and the drawing is
# made to be no help: every figure is built exactly, then its points are
# nudged a little (points that lie on a line stay on it, crossings stay
# crossings), so the equal parts come out drawn 3–12% apart while some decoy
# is drawn within 4% of the given part and closer to it than any answer. A
# child picking "the ones that look equal" picks wrong, and so does anyone
# reading the coordinates out of the page. The one exception is a vertical
# angle: two straight lines make it equal in any drawing at all.

module EqualKit
  module_function

  TRIANGLES = [ %w[A B C], %w[K L M], %w[P Q R], %w[D E F], %w[M N P], %w[E F G], %w[S T U], %w[X Y Z] ].freeze
  QUADS = [ %w[A B C D], %w[K L M N], %w[P Q R S], %w[M N P Q], %w[E F G H], %w[W X Y Z] ].freeze
  EXTRA = %w[M P O Q L D E H K N T].freeze

  # Letters for the auxiliary points, none of them already a vertex.
  def extra(c, taken, count) = c.sample(EXTRA - taken, count)

  def mid(p, q) = [ (p[0] + q[0]) / 2.0, (p[1] + q[1]) / 2.0 ]
  def lerp(p, q, t) = [ p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t ]
  def dist(p, q) = Math.hypot(q[0] - p[0], q[1] - p[1])

  def angle(from, vertex, to)
    u = [ from[0] - vertex[0], from[1] - vertex[1] ]
    w = [ to[0] - vertex[0], to[1] - vertex[1] ]
    Math.acos(((u[0] * w[0] + u[1] * w[1]) / (Math.hypot(*u) * Math.hypot(*w))).clamp(-1, 1)) * 180 / Math::PI
  end

  # Where the line through p along d meets the line through q along e.
  def meet(p, d, q, e)
    det = d[0] * -e[1] - d[1] * -e[0]
    return nil if det.abs < 1e-9

    t = ((q[0] - p[0]) * -e[1] - (q[1] - p[1]) * -e[0]) / det
    [ p[0] + d[0] * t, p[1] + d[1] * t ]
  end

  def size(points, part)
    part.size == 2 ? dist(points[part[0]], points[part[1]]) : angle(points[part[0]], points[part[1]], points[part[2]])
  end

  def name(part) = part.size == 2 ? part.join : "∠#{part.join}"

  def project(point, p, q)
    d = [ q[0] - p[0], q[1] - p[1] ]
    t = ((point[0] - p[0]) * d[0] + (point[1] - p[1]) * d[1]) / (d[0]**2 + d[1]**2)
    [ p[0] + d[0] * t, p[1] + d[1] * t ]
  end

  # Two angles at one vertex whose rays point opposite ways: two straight lines
  # make them equal however the figure is drawn, so they cannot be nudged apart.
  def vertical?(points, given, part)
    return false unless part.size == 3 && part[1] == given[1]

    v = points[given[1]]
    ray = ->(name) { [ points[name][0] - v[0], points[name][1] - v[1] ].then { |x, y| l = Math.hypot(x, y); [ x / l, y / l ] } }
    opposite = ->(a, b) { (ray.(a)[0] * ray.(b)[0] + ray.(a)[1] * ray.(b)[1]) < -0.999 }
    (opposite.(part[0], given[0]) && opposite.(part[2], given[2])) || (opposite.(part[0], given[2]) && opposite.(part[2], given[0]))
  end

  # Takes the exact figure and returns one the eye cannot be trusted with, plus
  # the decoy drawn closest to the given part. Every point moves by up to
  # `amount` (on a 0–100 board); a point that lies on a line (`on`) is slid
  # back onto it, and a crossing (`cross`) is recomputed from the moved lines,
  # so the figure still reads as the construction. Kept only when, after the
  # kit's rounding: every answer part that is not a vertical angle is drawn
  # 3–12% away from the given part, some decoy of the same kind within 4% —
  # and nearer than any of those answers.
  def settle(c, exact, given, equal, segments, angles, on: {}, cross: {}, amount: 25)
    pool = given.size == 2 ? segments : angles
    decoys = pool - [ given ] - equal
    raise Authoring::Duplicate if decoys.size < 3

    400.times do
      pts = exact.transform_values { |x, y| [ x + c.int(-amount..amount) / 10.0, y + c.int(-amount..amount) / 10.0 ] }
      on.each { |point, (p, q)| pts[point] = project(pts[point], pts[p], pts[q]) }
      crossed = cross.all? do |point, ((a, b), (d, e))|
        pts[point] = meet(pts[a], [ pts[b][0] - pts[a][0], pts[b][1] - pts[a][1] ], pts[d], [ pts[e][0] - pts[d][0], pts[e][1] - pts[d][1] ])
      end
      next unless crossed

      pts = pts.transform_values { |x, y| [ x.round(1), y.round(1) ] }
      next unless pts.values.all? { |x, y| x.between?(3, 97) && y.between?(3, 97) }

      g = size(pts, given)
      off = ->(part) { (size(pts, part) - g).abs / g }
      free = equal.reject { |part| vertical?(pts, given, part) }
      next unless free.all? { |part| off.(part).between?(0.03, 0.12) }

      closest = decoys.min_by { |part| off.(part) }
      next unless off.(closest) <= 0.04
      next unless free.empty? || off.(closest) < free.map(&off).min

      return [ pts, closest ]
    end
    raise Authoring::Duplicate
  end

  def list(parts) = parts.map { |part| name(part) }.join(", ")

  # „отсечката … не е равна“, „ъгълът … не е равен“.
  def equal_word(part) = part.size == 2 ? "равна" : "равен"
  def pronoun(part) = part.size == 2 ? "я" : "го"
end

# ------------------------------------------------------- Симетрала на отсечка ---

Authoring.family "working.equal.perpendicular_bisector", topic: "Еднакви триъгълници", area: "interactive_working", variants: 8,
                 rungs: [ 1250, 1310, 1370, 1430, 1490, 1550 ] do |c|
  a, b, cc = c.pick(EqualKit::TRIANGLES)
  on_bc = [ 2, 3 ].include?(c.level) && c.coin
  # The bisector of AB only meets AC when C is past the middle of AB, on B's
  # side (and BC when C is on A's side); a low C keeps AM close to AP, which
  # is the decoy that makes the figure untrustworthy by eye.
  cx = if c.level >= 4 then c.int(32..68)
  elsif on_bc then c.int(16..42)
  else c.int(58..84)
  end
  pts = {
    a => [ c.int(6..20), c.int(78..92) ],
    b => [ c.int(80..94), c.int(76..92) ],
    cc => [ cx, c.level >= 4 ? c.int(8..24) : c.int(26..52) ]
  }
  base = [ pts[b][0] - pts[a][0], pts[b][1] - pts[a][1] ]
  normal = [ -base[1], base[0] ]

  if c.level >= 4
    p, q, o = EqualKit.extra(c, [ a, b, cc ], 3)
    pts[p] = EqualKit.mid(pts[a], pts[b])
    pts[q] = EqualKit.mid(pts[b], pts[cc])
    side = [ pts[cc][0] - pts[b][0], pts[cc][1] - pts[b][1] ]
    pts[o] = EqualKit.meet(pts[p], normal, pts[q], [ -side[1], side[0] ]) or raise Authoring::Duplicate
    raise Authoring::Duplicate unless [ [ a, b, cc ], [ b, cc, a ], [ cc, a, b ] ].all? { |x, y, z| EqualKit.angle(pts[x], pts[y], pts[z]) < 82 }

    segments = [ [ o, a ], [ o, b ], [ o, cc ], [ a, p ], [ p, b ], [ b, q ], [ q, cc ], [ cc, a ] ]
    given, equal = c.level == 4 ? [ [ o, a ], [ [ o, b ], [ o, cc ] ] ] : [ [ o, b ], [ [ o, a ], [ o, cc ] ] ]
    lines = [ [ p, o, "s₁" ], [ q, o, "s₂" ] ]
    pts, near = EqualKit.settle(c, pts, given, equal, segments, [], on: { p => [ a, b ], q => [ b, cc ] })
    text = "Правите s₁ и s₂ са симетрали на страните #{a}#{b} и #{b}#{cc} на триъгълника #{a}#{b}#{cc}: минават през средите им #{p} и #{q} " \
           "и се пресичат в точка #{o}. Посочи всички отсечки, равни на #{EqualKit.name(given)}."
    steps = [
      "#{o} лежи на симетралата на #{a}#{b}, затова #{o}#{a} = #{o}#{b}.",
      "#{o} лежи и на симетралата на #{b}#{cc}, затова #{o}#{b} = #{o}#{cc}.",
      "Значи и трите отсечки #{o}#{a}, #{o}#{b} и #{o}#{cc} са равни — #{o} е на еднакво разстояние от трите върха."
    ]
    idea = "Всяка точка от симетралата на една отсечка е на равни разстояния от двата ѝ края. Точка на две симетрали е на равни разстояния от трите върха."
    check = "#{o} е центърът на окръжността през #{a}, #{b} и #{cc}: и трите отсечки са нейни радиуси."
  else
    p, m = EqualKit.extra(c, [ a, b, cc ], 2)
    far, near_end = on_bc ? [ b, a ] : [ a, b ]
    pts[p] = EqualKit.mid(pts[a], pts[b])
    side_dir = [ pts[cc][0] - pts[far][0], pts[cc][1] - pts[far][1] ]
    pts[m] = EqualKit.meet(pts[p], normal, pts[far], side_dir) or raise Authoring::Duplicate
    t = EqualKit.dist(pts[far], pts[m]) / EqualKit.dist(pts[far], pts[cc])
    raise Authoring::Duplicate unless t.between?(0.2, 0.85)

    segments = [ [ a, p ], [ p, b ], [ far, m ], [ m, cc ], [ near_end, m ], [ near_end, cc ] ]
    given, equal = if c.level.zero?
      [ [ a, p ], [ [ p, b ] ] ]
    elsif c.level == 3
      [ [ near_end, m ], [ [ far, m ] ] ]
    else
      [ [ far, m ], [ [ near_end, m ] ] ]
    end
    lines = [ [ p, m, "s" ] ]
    pts, near = EqualKit.settle(c, pts, given, equal, segments, [], on: { p => [ a, b ], m => [ far, cc ] })
    text = "Правата s е симетрала на страната #{a}#{b} на триъгълника #{a}#{b}#{cc}. Тя пресича #{a}#{b} в точка #{p} и #{far}#{cc} в точка #{m}. " \
           "Посочи всички отсечки, равни на #{EqualKit.name(given)}."
    steps = if c.level.zero?
      [ "Симетралата минава през средата на #{a}#{b}, значи #{p} е средата и #{a}#{p} = #{p}#{b}.",
        "Другите отсечки на чертежа не са части от #{a}#{b} и нищо не ги прави равни на #{a}#{p}." ]
    else
      [ "#{m} лежи на симетралата на #{a}#{b}, затова е на равни разстояния от #{a} и #{b}: #{m}#{a} = #{m}#{b}.",
        "#{m}#{cc} е само част от страната #{far}#{cc} — тя не е равна на #{EqualKit.name(given)}, колкото и да прилича." ]
    end
    idea = "Всяка точка от симетралата на една отсечка е на равни разстояния от двата ѝ края."
    check = "Ако сгънеш чертежа по s, #{a} пада върху #{b} — и всяка отсечка от точка на s до #{a} се покрива с отсечката до #{b}."
  end

  c.q(
    text: text,
    widget: WidgetKit.equal_parts(points: pts, given: given, equal: equal, segments: segments, lines: lines),
    explanation: Explain.build(
      idea: idea,
      steps: steps,
      answer: EqualKit.list(equal),
      check: check,
      watch: "#{EqualKit.name(near)} изглежда почти колкото #{EqualKit.name(given)}, но нищо в построението не #{EqualKit.pronoun(near)} прави #{EqualKit.equal_word(near)}. Чертежът не е в мащаб — гледа се построението."
    ),
    hints: [
      "Какво е вярно за всяка точка, която лежи на симетралата на една отсечка?",
      "Сравни разстоянията от такава точка до двата края на разполовената отсечка."
    ]
  )
end

# ------------------------------------------------------------- Ъглополовяща ---

Authoring.family "working.equal.angle_bisector", topic: "Ъгли", area: "interactive_working", variants: 8,
                 rungs: [ 1200, 1260, 1320, 1380, 1440, 1500 ] do |c|
  a, b, cc = c.pick(EqualKit::TRIANGLES)
  isosceles = c.level >= 4
  pts = { a => [ c.int(6..20), c.int(76..92) ], b => [ c.int(80..94), c.int(76..92) ] }
  pts[b][1] = pts[a][1] if isosceles # an isosceles triangle needs its apex over the middle of a level base
  if isosceles
    middle = EqualKit.mid(pts[a], pts[b])
    half = EqualKit.dist(pts[a], pts[b]) / 2
    height = half * c.int(86..118) / 100.0
    pts[cc] = [ middle[0], middle[1] - height ]
  elsif c.level.between?(2, 3)
    # Corners A and B close but not equal, so the halves of one look like the
    # halves of the other.
    offset = c.pick([ -14, -11, -8, -5, 5, 8, 11, 14 ])
    pts[cc] = [ (pts[a][0] + pts[b][0]) / 2.0 + offset, c.int(14..44) ]
  else
    # A wide angle at C, so each of its halves is about the size of the
    # corners at A and B.
    pts[cc] = [ c.int(32..68), c.int(46..62) ]
  end

  l = nil
  if c.level.between?(2, 3)
    i = EqualKit.extra(c, [ a, b, cc ], 1).first
    # The incentre: where the bisectors from the two base corners meet.
    la, lb, lc = EqualKit.dist(pts[b], pts[cc]), EqualKit.dist(pts[a], pts[cc]), EqualKit.dist(pts[a], pts[b])
    total = la + lb + lc
    pts[i] = [ (la * pts[a][0] + lb * pts[b][0] + lc * pts[cc][0]) / total, (la * pts[a][1] + lb * pts[b][1] + lc * pts[cc][1]) / total ]
    # CI is a bisector too (the three meet in one point), so the halves at C
    # are equal to each other — but not to the halves at A or B.
    segments = [ [ a, b ], [ b, cc ], [ cc, a ], [ a, i ], [ b, i ], [ cc, i ] ]
    angles = [ [ i, a, b ], [ cc, a, i ], [ a, b, i ], [ i, b, cc ], [ a, cc, i ], [ i, cc, b ], [ a, i, b ] ]
    given, equal = c.level == 2 ? [ [ i, a, b ], [ [ cc, a, i ] ] ] : [ [ i, b, cc ], [ [ a, b, i ] ] ]
    text = "Ъглополовящите на ъглите при #{a} и #{b} в триъгълника #{a}#{b}#{cc} се пресичат в точка #{i}. " \
           "Посочи всички ъгли, равни на #{EqualKit.name(given)}."
    vertex = given[1]
    steps = [
      "#{vertex}#{i} е ъглополовяща на ъгъла при #{vertex}, значи го дели на две равни части: #{EqualKit.name(given)} = #{EqualKit.list(equal)}.",
      "Трите ъглополовящи минават през #{i}, затова и #{cc}#{i} разполовява ъгъла при #{cc}. Половините при #{vertex == a ? b : a} и при #{cc} са равни помежду си, но не и на половините при #{vertex} — ъглите на триъгълника са различни."
    ]
  else
    l = EqualKit.extra(c, [ a, b, cc ], 1).first
    ca, cb = EqualKit.dist(pts[cc], pts[a]), EqualKit.dist(pts[cc], pts[b])
    pts[l] = EqualKit.lerp(pts[a], pts[b], ca / (ca + cb))
    segments = [ [ a, l ], [ l, b ], [ a, cc ], [ b, cc ], [ cc, l ] ]
    angles = [ [ a, cc, l ], [ l, cc, b ], [ cc, a, b ], [ a, b, cc ], [ a, l, cc ], [ cc, l, b ] ]
    angles << [ a, cc, b ] if c.level == 5
    given, equal = case c.level
    when 0 then [ [ a, cc, l ], [ [ l, cc, b ] ] ]
    when 1 then [ [ l, cc, b ], [ [ a, cc, l ] ] ]
    when 4 then [ [ a, l ], [ [ l, b ] ] ]
    else [ [ a, l, cc ], [ [ cc, l, b ] ] ]
    end
    text = if isosceles
      "В триъгълника #{a}#{b}#{cc} е дадено #{cc}#{a} = #{cc}#{b}, а #{cc}#{l} е ъглополовяща на ∠#{a}#{cc}#{b}. " \
        "Посочи всички #{given.size == 2 ? 'отсечки' : 'ъгли'}, равни на #{EqualKit.name(given)}."
    else
      "#{cc}#{l} е ъглополовяща на ∠#{a}#{cc}#{b} в триъгълника #{a}#{b}#{cc}. Посочи всички ъгли, равни на #{EqualKit.name(given)}."
    end
    steps = if isosceles
      [ "В равнобедрен триъгълник ъглополовящата към основата е и медиана, и височина.",
        given.size == 2 ? "Като медиана тя разполовява основата: #{a}#{l} = #{l}#{b}." :
                          "Като височина тя е перпендикулярна на основата: ∠#{a}#{l}#{cc} = ∠#{cc}#{l}#{b} = 90°." ]
    else
      [ "Ъглополовящата дели ъгъла на две равни части: ∠#{a}#{cc}#{l} = ∠#{l}#{cc}#{b}.",
        "Ъглите при #{a} и #{b} са ъгли на триъгълника — нищо не ги прави равни на половината от ъгъла при #{cc}." ]
    end
  end
  pts, near = EqualKit.settle(c, pts, given, equal, segments, angles, on: c.level.between?(2, 3) ? {} : { l => [ a, b ] })

  c.q(
    text: text,
    widget: WidgetKit.equal_parts(points: pts, given: given, equal: equal, segments: segments, angles: angles),
    explanation: Explain.build(
      idea: isosceles ? "В равнобедрен триъгълник ъглополовящата от върха е и медиана, и височина." :
                        "Ъглополовящата на един ъгъл го дели на два равни ъгъла.",
      steps: steps,
      answer: EqualKit.list(equal),
      check: "Отбелязаните части се получават една от друга при отражение спрямо ъглополовящата#{isosceles ? ' — в равнобедрения триъгълник тя е и ос на симетрия' : ''}.",
      watch: "#{EqualKit.name(near)} изглежда почти като #{EqualKit.name(given)}, но не е #{EqualKit.equal_word(near)} по построение. Чертежът не е в мащаб."
    ),
    hints: [
      isosceles ? "Какви други свойства има ъглополовящата от върха на равнобедрен триъгълник?" : "На колко части и какви дели ъгъла една ъглополовяща?",
      "Търси частите, които се получават една от друга при отражение спрямо ъглополовящата."
    ]
  )
end

# ------------------------------------------------- Равнобедрен и равностранен ---

Authoring.family "working.equal.isosceles", topic: "Еднакви триъгълници", area: "interactive_working", variants: 8,
                 rungs: [ 1100, 1160, 1220, 1280, 1340, 1400 ] do |c|
  a, b, cc = c.pick(EqualKit::TRIANGLES)
  left = [ c.int(8..18), c.int(80..92) ]
  width = c.int(64..80)
  segments = []
  angles = []

  case c.level
  when 0, 1, 5
    # With the legs given, the decoy is the height CM, which is sin β of a leg:
    # steep base angles bring it within a few percent of the legs.
    beta = c.pick(c.level == 1 ? [ 72, 73, 74, 75, 76, 77, 78 ] : [ 56, 57, 58, 59, 61, 62, 63, 64 ])
    width = c.int(30..40) if c.level == 1
    pts = { a => left, b => [ left[0] + width, left[1] ] }
    pts[cc] = [ left[0] + width / 2.0, left[1] - (width / 2.0) * Math.tan(beta * Math::PI / 180) ]
    if c.level == 5
      d, e = EqualKit.extra(c, [ a, b, cc ], 2)
      share = c.int(10..20) / 100.0
      pts[d] = EqualKit.lerp(pts[a], pts[b], share)
      pts[e] = EqualKit.lerp(pts[a], pts[b], 1 - share)
      segments = [ [ a, d ], [ d, e ], [ e, b ], [ cc, a ], [ cc, b ], [ cc, d ], [ cc, e ] ]
      given, equal = [ [ cc, d ], [ [ cc, e ] ] ]
      text = "В триъгълника #{a}#{b}#{cc} е дадено #{cc}#{a} = #{cc}#{b}. Точките #{d} и #{e} лежат на #{a}#{b}, като #{a}#{d} = #{e}#{b}. " \
             "Посочи всички отсечки, равни на #{cc}#{d}."
      on = { d => [ a, b ], e => [ a, b ] }
      hints = [ "Сравни триъгълниците #{a}#{d}#{cc} и #{b}#{e}#{cc}: кои техни страни и ъгли са дадени или следват от даденото?",
                "Две страни и ъгълът между тях — какво казва това за двата триъгълника?" ]
      idea = "Два триъгълника с две равни страни и равен ъгъл между тях са еднакви — и съответните им страни са равни."
      steps = [
        "В триъгълниците #{a}#{d}#{cc} и #{b}#{e}#{cc}: #{cc}#{a} = #{cc}#{b} (дадено), #{a}#{d} = #{b}#{e} (дадено) и ∠#{cc}#{a}#{b} = ∠#{cc}#{b}#{a} (ъгли при основата на равнобедрения триъгълник).",
        "Значи триъгълниците са еднакви и #{cc}#{d} = #{cc}#{e}."
      ]
      check = "Отражението спрямо височината от #{cc} разменя #{a} с #{b} и #{d} с #{e} — то пренася #{cc}#{d} върху #{cc}#{e}."
    else
      m = EqualKit.extra(c, [ a, b, cc ], 1).first
      pts[m] = EqualKit.mid(pts[a], pts[b])
      segments = [ [ a, m ], [ m, b ], [ cc, a ], [ cc, b ], [ cc, m ] ]
      angles = [ [ cc, a, b ], [ cc, b, a ], [ a, cc, b ], [ a, cc, m ], [ m, cc, b ], [ a, m, cc ] ]
      if c.level.zero?
        given, equal = c.coin ? [ [ cc, a, b ], [ [ cc, b, a ] ] ] : [ [ cc, b, a ], [ [ cc, a, b ] ] ]
      else
        given, equal = c.coin ? [ [ cc, a ], [ [ cc, b ] ] ] : [ [ cc, b ], [ [ cc, a ] ] ]
      end
      text = "В триъгълника #{a}#{b}#{cc} страните #{cc}#{a} и #{cc}#{b} са равни, а #{m} е средата на #{a}#{b}. " \
             "Посочи всички #{given.size == 2 ? 'отсечки' : 'ъгли'}, равни на #{EqualKit.name(given)}."
      on = { m => [ a, b ] }
      hints = [ "Кои страни са дадени като равни и кой връх е между тях?", "Срещу равни страни лежат равни ъгли — и обратно." ]
      idea = given.size == 2 ? "В равнобедрен триъгълник бедрата са равни." : "В равнобедрен триъгълник ъглите при основата са равни."
      steps = [
        given.size == 2 ? "Дадено е, че #{cc}#{a} = #{cc}#{b} — това са бедрата." : "Ъглите при основата #{a}#{b} — при #{a} и при #{b} — са равни, защото #{cc}#{a} = #{cc}#{b}.",
        given.size == 2 ? "#{cc}#{m} дели триъгълника на два еднакви триъгълника, но самата отсечка #{cc}#{m} не е равна на #{EqualKit.name(given)}." :
                          "#{cc}#{m} дели триъгълника на два еднакви триъгълника, но ъглите при #{cc} и при #{m} не са равни на #{EqualKit.name(given)}."
      ]
      check = "Отражението спрямо #{cc}#{m} разменя #{a} и #{b} и пренася #{EqualKit.name(given)} върху #{EqualKit.list(equal)}."
    end
  when 2
    pts = { b => left, cc => [ left[0] + width, left[1] ] }
    apex = c.pick([ 50, 52, 54, 56, 64, 66, 68, 70 ])
    pts[a] = [ left[0] + width / 2.0, left[1] - (width / 2.0) / Math.tan(apex / 2.0 * Math::PI / 180) ]
    raise Authoring::Duplicate unless pts[a][1] > 4

    d = EqualKit.extra(c, [ a, b, cc ], 1).first
    pts[d] = EqualKit.lerp(pts[b], pts[cc], c.int(25..40) / 100.0)
    segments = [ [ a, b ], [ a, cc ], [ b, d ], [ d, cc ], [ a, d ] ]
    angles = [ [ a, b, cc ], [ a, cc, b ], [ b, a, cc ], [ b, a, d ], [ d, a, cc ], [ a, d, b ], [ a, d, cc ] ]
    given, equal = c.coin ? [ [ a, b, cc ], [ [ a, cc, b ] ] ] : [ [ a, cc, b ], [ [ a, b, cc ] ] ]
    text = "В триъгълника #{a}#{b}#{cc} е дадено #{a}#{b} = #{a}#{cc}, а точката #{d} лежи на #{b}#{cc}. Посочи всички ъгли, равни на #{EqualKit.name(given)}."
    on = { d => [ b, cc ] }
    hints = [ "Кои страни са дадени като равни и кой връх е между тях?", "Срещу равни страни лежат равни ъгли — и обратно." ]
    idea = "В равнобедрен триъгълник ъглите при основата са равни — основата е страната срещу върха, от който излизат равните страни."
    steps = [
      "Равните страни #{a}#{b} и #{a}#{cc} излизат от #{a}, значи основата е #{b}#{cc}.",
      "Ъглите при основата са при #{b} и при #{cc}: #{EqualKit.name(given)} = #{EqualKit.list(equal)}. Отсечката #{a}#{d} не е ъглополовяща и не разделя нищо на равни части."
    ]
    check = "Срещу равни страни лежат равни ъгли: срещу #{a}#{cc} е ъгълът при #{b}, срещу #{a}#{b} — ъгълът при #{cc}."
  else
    side = c.int(50..58)
    origin = [ c.int(6..12), c.int(84..92) ]
    pts = { a => origin, b => [ origin[0] + side, origin[1] ], cc => [ origin[0] + side / 2.0, origin[1] - side * Math.sqrt(3) / 2 ] }
    d, e = EqualKit.extra(c, [ a, b, cc ], 2)

    # A second triangle on BC, close to equilateral but not, as the decoy: D
    # sits a little nearer or farther from B than a side's length.
    reach = side * c.pick([ 0.88, 0.9, 0.92, 1.08, 1.1 ])
    turn = c.int(66..76) * Math::PI / 180
    pts[d] = [ pts[b][0] + reach * Math.cos(turn), pts[b][1] - reach * Math.sin(turn) ]
    pts[e] = [ pts[a][0] + c.int(0..4), pts[cc][1] + c.int(2..10) ]
    segments = [ [ a, b ], [ b, cc ], [ cc, a ], [ b, d ], [ cc, d ], [ a, e ], [ cc, e ] ]
    angles = [ [ cc, a, b ], [ a, b, cc ], [ b, cc, a ], [ d, b, cc ], [ b, cc, d ], [ b, d, cc ] ]
    if c.level == 3
      given, equal = [ [ a, b ], [ [ b, cc ], [ cc, a ] ] ]
    else
      given, equal = [ [ cc, a, b ], [ [ a, b, cc ], [ b, cc, a ] ] ]
    end
    text = "Триъгълникът #{a}#{b}#{cc} е равностранен. До страните му #{b}#{cc} и #{cc}#{a} са начертани триъгълниците #{b}#{cc}#{d} и #{a}#{cc}#{e}. " \
           "Посочи всички #{given.size == 2 ? 'отсечки' : 'ъгли'}, равни на #{EqualKit.name(given)}."
    on = {}
    hints = given.size == 2 ? [ "Какво казва думата „равностранен“ за страните на триъгълника?", "Сравни само страните на равностранния триъгълник — останалите отсечки са от други триъгълници." ] :
                              [ "Колко градуса е всеки ъгъл на равностранен триъгълник?", "Сравни само ъглите на равностранния триъгълник — останалите са от други триъгълници." ]
    idea = "В равностранен триъгълник и трите страни, и трите ъгъла са равни (всеки ъгъл е 60°)."
    steps = [
      given.size == 2 ? "Страните на равностранния триъгълник са #{a}#{b}, #{b}#{cc} и #{cc}#{a} — и трите са равни." :
                        "Ъглите на равностранния триъгълник са при #{a}, #{b} и #{cc} — и трите са по 60°.",
      "Частите при #{d} и #{e} са от други триъгълници: нищо не казва, че те са равностранни."
    ]
    check = given.size == 2 ? "Равностранен значи „с равни страни“ — и трите." : "Сборът на ъглите е 180°, а три равни ъгъла дават по 60°."
  end
  pts, near = EqualKit.settle(c, pts, given, equal, segments, angles, on: on)

  c.q(
    text: text,
    widget: WidgetKit.equal_parts(points: pts, given: given, equal: equal, segments: segments, angles: angles),
    explanation: Explain.build(
      idea: idea,
      steps: steps,
      answer: EqualKit.list(equal),
      check: check,
      watch: "#{EqualKit.name(near)} изглежда почти колкото #{EqualKit.name(given)}, но не е #{EqualKit.equal_word(near)} по построение. Чертежът не е в мащаб."
    ),
    hints: hints
  )
end

# ---------------------------------------------- Успоредник, ромб, правоъгълник ---

Authoring.family "working.equal.quadrilateral", topic: "Еднакви триъгълници", area: "interactive_working", variants: 8,
                 rungs: [ 1300, 1370, 1440, 1510, 1580, 1650 ] do |c|
  a, b, cc, d = c.pick(EqualKit::QUADS)
  o = "O"
  corners = [ a, b, cc, d ]
  origin = [ c.int(8..20), c.int(78..90) ]

  # u runs along AB, v along AD; C = A + u + v.
  u, v = case c.level
  when 0
    len = c.int(44..54)
    ratio = c.pick([ 0.9, 0.92, 0.94, 1.06, 1.08, 1.1 ])
    tilt = c.int(55..70) * Math::PI / 180
    [ [ len, 0 ], [ len * ratio * Math.cos(tilt), -len * ratio * Math.sin(tilt) ] ]
  when 1
    tilt = c.int(85..88) * Math::PI / 180
    [ [ c.int(46..58), 0 ], [ c.int(40..56) * Math.cos(tilt), -c.int(40..56) * Math.sin(tilt) ] ]
  when 2
    tilt = c.int(62..76) * Math::PI / 180
    [ [ c.int(46..58), 0 ], [ c.int(46..58) * Math.cos(tilt), -c.int(46..58) * Math.sin(tilt) ] ]
  when 3
    short = c.int(34..42)
    [ [ (short * c.pick([ 1.5, 1.6, 1.7, 1.8, 1.9 ])).round, 0 ], [ 0, -short ] ]
  else
    side = c.int(44..52)
    angle = (c.level == 4 ? c.int(46..56) : c.int(82..87)) * Math::PI / 180
    [ [ side, 0 ], [ side * Math.cos(angle), -side * Math.sin(angle) ] ]
  end
  pts = { a => origin, b => [ origin[0] + u[0], origin[1] + u[1] ],
          cc => [ origin[0] + u[0] + v[0], origin[1] + u[1] + v[1] ], d => [ origin[0] + v[0], origin[1] + v[1] ] }
  sides = [ [ a, b ], [ b, cc ], [ cc, d ], [ d, a ] ]
  pick = c.int(0..3)
  shape = { 0 => "успоредник", 1 => "успоредник", 2 => "успоредник", 3 => "правоъгълник", 4 => "ромб", 5 => "ромб" }[c.level]
  segments = sides.dup
  angles = []
  cross = nil

  case c.level
  when 0
    segments += [ [ a, cc ], [ b, d ] ]
    given = sides[pick]
    equal = [ sides[(pick + 2) % 4] ]
    idea = "В успоредник срещуположните страни са равни."
    steps = [ "Срещуположната на #{EqualKit.name(given)} страна е #{EqualKit.name(equal.first)} — двете са равни.",
              "Съседните страни на успоредника не са равни на #{EqualKit.name(given)}, освен ако той не е ромб — а това не е дадено." ]
  when 1
    segments += [ [ a, cc ] ]
    corner = [ [ d, a, b ], [ a, b, cc ], [ b, cc, d ], [ cc, d, a ] ]
    angles = corner + [ [ cc, a, b ], [ a, cc, d ] ]
    given = corner[pick]
    equal = [ corner[(pick + 2) % 4] ]
    idea = "В успоредник срещуположните ъгли са равни, а съседните се допълват до 180°."
    steps = [ "Срещуположният на #{EqualKit.name(given)} ъгъл е #{EqualKit.name(equal.first)} — двата са равни.",
              "Съседните ъгли дават с #{EqualKit.name(given)} сбор 180°: те са равни на него само при правоъгълник." ]
  when 2, 3
    pts[o] = EqualKit.mid(pts[a], pts[cc])
    cross = { o => [ [ a, cc ], [ b, d ] ] }
    halves = [ [ o, a ], [ o, b ], [ o, cc ], [ o, d ] ]
    segments += halves
    given = halves[pick]
    equal = c.level == 2 ? [ halves[(pick + 2) % 4] ] : halves - [ given ]
    idea = c.level == 2 ? "Диагоналите на успоредника се разполовяват в пресечната си точка." :
                          "Диагоналите на правоъгълника са равни и се разполовяват — четирите половини са равни."
    steps = if c.level == 2
      [ "#{o} е средата и на двата диагонала, затова #{EqualKit.name(given)} е равна на другата половина на своя диагонал: #{EqualKit.name(equal.first)}.",
        "Половините на другия диагонал са равни помежду си, но диагоналите на успоредника не са равни един на друг." ]
    else
      [ "В правоъгълника #{a}#{cc} = #{b}#{d}, а #{o} е средата и на двата.",
        "Значи #{EqualKit.list(halves)} са половини на равни отсечки — и четирите са равни." ]
    end
  else
    if c.level == 4
      pts[o] = EqualKit.mid(pts[a], pts[cc])
      cross = { o => [ [ a, cc ], [ b, d ] ] }
      segments += [ [ o, a ], [ o, b ], [ o, cc ], [ o, d ] ]
      given = sides[pick]
      equal = sides - [ given ]
      idea = "Ромбът е успоредник с четири равни страни."
      steps = [ "И четирите страни на ромба са равни: #{EqualKit.list(sides)}.",
                "Половините на диагоналите са по-къси от страната: диагоналите на ромба са перпендикулярни, затова страната #{a}#{b} е хипотенуза в правоъгълния триъгълник #{a}#{o}#{b} — а хипотенузата е по-дълга от всеки катет." ]
    else
      segments += [ [ a, cc ], [ b, d ] ]
      at_ac = [ [ d, a, cc ], [ cc, a, b ], [ b, cc, a ], [ a, cc, d ] ]
      at_bd = [ [ a, b, d ], [ d, b, cc ], [ cc, d, b ], [ b, d, a ] ]
      angles = at_ac + at_bd
      group = pick.even? ? at_ac : at_bd
      given = group[c.int(0..3)]
      equal = group - [ given ]
      diagonal = group.equal?(at_ac) ? "#{a}#{cc}" : "#{b}#{d}"
      idea = "В ромба всеки диагонал е ъглополовяща на ъглите, през които минава, а срещуположните ъгли са равни."
      steps = [ "Диагоналът #{diagonal} разполовява двата ъгъла, през които минава — а те са равни като срещуположни ъгли на успоредник.",
                "Затова и четирите половини при краищата на #{diagonal} са равни: #{EqualKit.list(group)}.",
                "Половините при другия диагонал са равни помежду си, но не и на тези — освен ако ромбът е квадрат." ]
    end
  end
  pts, near = EqualKit.settle(c, pts, given, equal, segments, angles, cross: cross || {})
  part_word = given.size == 2 ? "отсечки" : "ъгли"
  diagonals = case c.level
  when 1 then ", а #{a}#{cc} е негов диагонал"
  when 2, 3, 4 then ", а диагоналите му се пресичат в точка #{o}"
  else ", а диагоналите му са #{a}#{cc} и #{b}#{d}"
  end

  c.q(
    text: "#{corners.join} е #{shape}#{diagonals}. Посочи всички #{part_word}, равни на #{EqualKit.name(given)}.",
    widget: WidgetKit.equal_parts(points: pts, given: given, equal: equal, segments: segments, angles: angles),
    explanation: Explain.build(
      idea: idea,
      steps: steps,
      answer: EqualKit.list(equal),
      check: "Завъртането на #{shape}а на 180° около пресечната точка на диагоналите пренася всяка страна и всеки ъгъл върху срещуположния.",
      watch: "#{EqualKit.name(near)} изглежда почти като #{EqualKit.name(given)}, но не е #{EqualKit.equal_word(near)} по построение. Чертежът не е в мащаб."
    ),
    hints: [
      "Кои свойства има всеки #{shape}? Започни от страните, ъглите и диагоналите.",
      "Кои части се разменят, ако завъртиш фигурата на 180° около средата ѝ?"
    ]
  )
end

# --------------------------------------------- Успоредни прави и трета права ---

Authoring.family "working.equal.parallels", topic: "Ъгли", area: "interactive_working", variants: 8,
                 rungs: [ 1150, 1210, 1270, 1330, 1390, 1450 ] do |c|
  k, l, m, n, p, q, s, t = c.pick([ %w[K L M N P Q S T], %w[A B C D P Q E F], %w[E F G H M N K L], %w[A B D E O Q S T],
                                     %w[K L M N O R S T], %w[A B C D M N E F] ])
  ya, yb = c.int(30..38), c.int(62..70)
  theta = c.int(86..89) * Math::PI / 180
  lean = c.coin ? 1 : -1
  px = c.int(46..58)
  run = (yb - ya) / Math.tan(theta) * lean
  pts = { k => [ 6, ya ], l => [ 94, ya ], m => [ 6, yb ], n => [ 94, yb ],
          p => [ px, ya ], q => [ px - run, yb ] }
  pts[s] = [ px + (ya - 6) / Math.tan(theta) * lean, 6 ]
  pts[t] = [ pts[q][0] - (94 - yb) / Math.tan(theta) * lean, 94 ]

  # Four angles round each crossing: top right, top left, bottom left, bottom
  # right. With the transversal leaning right the top-right ones are acute.
  spots = {
    "top_right_p" => [ l, p, s ], "top_left_p" => [ s, p, k ], "bottom_left_p" => [ k, p, q ], "bottom_right_p" => [ q, p, l ],
    "top_right_q" => [ n, q, p ], "top_left_q" => [ p, q, m ], "bottom_left_q" => [ m, q, t ], "bottom_right_q" => [ t, q, n ]
  }
  group_a = %w[top_right_p bottom_left_p top_right_q bottom_left_q]
  # The top two rungs ask about every position again, worded from the
  # transversal's side — a stem the lower rungs never use, so the texts stay
  # apart while the angles asked about get no easier.
  choices = c.by_level([ %w[top_right_p top_left_p], %w[bottom_left_p bottom_right_p], %w[top_right_q top_left_q],
                         %w[bottom_left_q bottom_right_q], %w[top_left_p bottom_right_q top_left_q bottom_right_p],
                         %w[top_right_p bottom_left_p top_right_q bottom_left_q] ])
  given_key = c.pick(choices)
  group = group_a.include?(given_key) ? group_a : spots.keys - group_a
  given = spots[given_key]
  equal = (group - [ given_key ]).map { |key| spots[key] }
  segments = [ [ k, l ], [ m, n ], [ s, t ] ]

  relation = lambda do |key|
    same_crossing = key[-1] == given_key[-1]
    same_spot = key.sub(/_[pq]\z/, "") == given_key.sub(/_[pq]\z/, "")
    interior = ->(spot) { %w[bottom_left_p bottom_right_p top_left_q top_right_q].include?(spot) }
    if same_crossing then "връхни"
    elsif same_spot then "съответни"
    elsif interior.(key) && interior.(given_key) then "кръстни вътрешни"
    else "кръстни външни"
    end
  end
  pts, near = EqualKit.settle(c, pts, given, equal, segments, spots.values,
                              cross: { p => [ [ k, l ], [ s, t ] ], q => [ [ m, n ], [ s, t ] ] })

  c.q(
    text: (c.level >= 4 ? "Правата #{s}#{t} пресича успоредните прави #{k}#{l} и #{m}#{n} съответно в точките #{p} и #{q}. " :
                          "Успоредните прави #{k}#{l} и #{m}#{n} са пресечени от правата #{s}#{t} в точките #{p} и #{q}. ") +
          "Посочи всички ъгли, равни на #{EqualKit.name(given)}.",
    widget: WidgetKit.equal_parts(points: pts, given: given, equal: equal, segments: segments, angles: spots.values),
    explanation: Explain.build(
      idea: "При две успоредни прави и трета права връхните, съответните и кръстните ъгли са равни. Около всяка пресечна точка има по два вида ъгли: остри и тъпи.",
      steps: (group - [ given_key ]).map { |key| "#{EqualKit.name(given)} и #{EqualKit.name(spots[key])} са #{relation.(key)} ъгли." } +
             [ "Останалите четири ъгъла допълват #{EqualKit.name(given)} до 180°." ],
      answer: EqualKit.list(equal),
      check: "#{EqualKit.name(given)} и всеки от отбелязаните са еднакво „отворени“ — всички остри или всички тъпи. Съседните ъгли дават сбор 180°.",
      watch: "Правата #{s}#{t} е почти перпендикулярна на #{k}#{l} и #{EqualKit.name(near)} изглежда колкото #{EqualKit.name(given)}, но двата се допълват до 180° — не са равни. Чертежът не е в мащаб."
    ),
    hints: [
      "Около всяка пресечна точка кои два ъгъла са връхни?",
      "Кои ъгли стоят на едно и също място при двете пресечни точки, ако правите са успоредни?"
    ]
  )
end
