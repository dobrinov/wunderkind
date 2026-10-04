Glyphs engraved on the badge medals — Lucide 0.469.0, ISC licensed, vendored.

Fetched once rather than linked from unpkg, because this app serves every asset
itself: the design doc these came from masks them straight off a CDN, and a
child's tablet on a school network is the wrong place to discover that a third
party is down. Refresh with:

    for i in play pencil-line flame check-check chevrons-up graduation-cap \
             swords crown target mountain-snow trending-up sunrise lock; do
      curl -s "https://unpkg.com/lucide-static@0.469.0/icons/$i.svg" \
        -o "app/assets/images/badges/$i.svg"
    done

One file per `Badges::Badge#glyph`. Adding a badge with a new glyph means
adding its file here — `Badges.glyphs` is checked against this directory by
the spec, so a missing one fails rather than rendering a blank medal.
