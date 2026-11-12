import { Controller } from "@hotwired/stimulus"

// „Принтирай" on a public page: the page's own print styles (`print:hidden` on
// the header, the footer and the pitch) decide what reaches the paper.
export default class extends Controller {
  print() {
    window.print()
  }
}
