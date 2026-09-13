# Rasterizes the sharing card behind og:image.
#
# The template is ERB and rendered inside Rails so the figures on it come off
# the constants that implement them, exactly as the landing page's do — the card
# is the one surface where a number could go stale unseen, because it is a
# picture and nobody reads a picture against the code.
namespace :og_card do
  TEMPLATE = Rails.root.join("tools/og/card.html.erb")
  OUTPUT = Rails.root.join("public/og-card.png")

  desc "Render tools/og/card.html.erb to public/og-card.png (needs headless Chrome)"
  task build: :environment do
    html = ERB.new(TEMPLATE.read).result(binding)
    rendered = Rails.root.join("tmp/og-card.html")
    rendered.write(html)

    chrome = ENV.fetch("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
    abort "No Chrome at #{chrome}. Set CHROME=/path/to/chrome." unless File.executable?(chrome)

    system(chrome, "--headless", "--disable-gpu", "--hide-scrollbars",
           "--force-device-scale-factor=1", "--window-size=1200,630",
           "--virtual-time-budget=6000", "--screenshot=#{OUTPUT}",
           "file://#{rendered}", exception: true, out: File::NULL, err: File::NULL)

    puts "Wrote #{OUTPUT} (#{OUTPUT.size} bytes)"
  end
end
