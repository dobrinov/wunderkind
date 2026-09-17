import { Controller } from "@hotwired/stimulus"
import { preview } from "../lib/sounds"

// Lets /design-system play the two answer cues on demand. It plays them past
// the student's own switch: a page whose job is to let you hear the sounds
// would be useless if it were the one place they could be silenced.
export default class extends Controller {
  play(event) {
    preview(event.params.cue)
  }
}
