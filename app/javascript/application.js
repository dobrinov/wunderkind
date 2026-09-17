import "@hotwired/turbo-rails"
import "./controllers"
// Imported for its side effect: it listens for turbo:load and sends whatever
// event the last request queued. See lib/analytics.js.
import "./lib/analytics"
