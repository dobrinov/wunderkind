# The coin's art (shared/_coin): one SVG template, a palette per material and a
# Lucide symbol per track, drawn in code so it stays sharp from 24px to 160px
# and a new track costs one symbol. After the design canvas's „game coins"
# board: a thick rim, a recessed face darker towards the bottom right, a raised
# symbol with a hard shadow and one gloss streak.
module CoinsHelper
  PALETTES = {
    "wood" => { rim: "#cf9a66", edge: "#8a5a2b", face: "#ab7642", face_dark: "#986537", icon: "#e3b383", shadow: "#6e4520" },
    "bronze" => { rim: "#eaa265", edge: "#a95a22", face: "#c97837", face_dark: "#b5672a", icon: "#f6b77a", shadow: "#83420f" },
    "iron" => { rim: "#99a0aa", edge: "#4f555e", face: "#6f7682", face_dark: "#626874", icon: "#b2b8c1", shadow: "#3a3f47" },
    "silver" => { rim: "#eef1f5", edge: "#9aa3b0", face: "#c4cbd5", face_dark: "#b2bac6", icon: "#ffffff", shadow: "#7c8594" },
    "gold" => { rim: "#f9d63c", edge: "#d99a00", face: "#e7ad1f", face_dark: "#d99b13", icon: "#ffe72e", shadow: "#b77800" },
    "platinum" => { rim: "#dfeef5", edge: "#6f97ad", face: "#a9c7d7", face_dark: "#97b8ca", icon: "#f2f9fc", shadow: "#557f97" },
    "diamond" => { rim: "#c6f3ff", edge: "#1e9cd0", face: "#78d5f4", face_dark: "#5fc8ee", icon: "#eafcff", shadow: "#167fb0" },
    # An empty slot: the same coin in greys, with a dashed rim.
    "empty" => { rim: "#f5f5fa", edge: "#e5e5ef", face: "#ececf4", face_dark: "#e5e5ef", icon: "#c5c5d6", shadow: "#ffffff" }
  }.freeze

  SYMBOLS = {
    "bulb" => [ "M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5", "M9 18h6", "M10 22h4" ],
    "trend" => [ "M22 7 13.5 15.5 8.5 10.5 2 17", "M16 7h6v6" ],
    "flag" => [ "M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z", "M4 22v-7" ],
    "mountain" => [ "m8 3 4 8 5-5 5 15H2L8 3z" ],
    "target" => [ "M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20", "M12 6a6 6 0 1 0 0 12a6 6 0 1 0 0-12", "M12 10a2 2 0 1 0 0 4a2 2 0 1 0 0-4" ],
    "calendar" => [ "M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z", "M16 2v4", "M8 2v4", "M3 10h18", "m9 16 2 2 4-4" ],
    "finish" => [ "M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20", "m9 12 2 2 4-4" ],
    "login" => [ "M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4", "m10 17 5-5-5-5", "M15 12H3" ],
    "search" => [ "M11 3a8 8 0 1 0 0 16a8 8 0 1 0 0-16", "m21 21-4.3-4.3" ],
    "pencil" => [ "M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z", "m15 5 4 4" ],
    "users" => [ "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2", "M9 3a4 4 0 1 0 0 8a4 4 0 1 0 0-8", "M22 21v-2a4 4 0 0 0-3-3.87", "M16 3.13a4 4 0 0 1 0 7.75" ],
    "gift" => [ "M4 8h16a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z", "M12 8v13", "M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7", "M7.5 8a2.5 2.5 0 0 1 0-5C9.5 3 11 5 12 8c1-3 2.5-5 4.5-5a2.5 2.5 0 0 1 0 5" ],
    "swords" => [ "M14.5 17.5 3 6V3h3l11.5 11.5", "M13 19l6-6", "M16 16l4 4", "M19 21l2-2", "M14.5 6.5 18 3h3v3l-3.5 3.5", "M5 14l4 4", "M7 17l-3 3", "M3 19l2 2" ],
    "rotate" => [ "M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8", "M3 3v5h5" ]
  }.freeze

  # A unique clip-path id per drawn coin: a page shows many, and ids collide.
  def coin_clip_id
    @coin_clip_counter = (@coin_clip_counter || 0) + 1
    "coin-clip-#{@coin_clip_counter}"
  end

  def coin_material_name(material) = t("coins.materials.#{material}")
  def coin_track_name(track) = t("coins.tracks.#{track.key}.name")

  # „Злато · Научих я!" — what a coin is, read by a screen reader.
  def coin_label(track, rung)
    "#{coin_material_name(track.material(rung))} · #{coin_track_name(track)}"
  end
end
