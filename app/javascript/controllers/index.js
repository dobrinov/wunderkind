import { Application } from "@hotwired/stimulus"
import { registerLazy } from "../lib/lazy_controllers"

import FlashController from "./flash_controller"
import MenuController from "./menu_controller"
import AnswerFormController from "./answer_form_controller"
import ScrollShadowsController from "./scroll_shadows_controller"
import QuestionFormController from "./question_form_controller"
import NumberLineController from "./widgets/number_line_controller"
import OrderingController from "./widgets/ordering_controller"
import FractionBarsController from "./widgets/fraction_bars_controller"
import MultiSelectController from "./widgets/multi_select_controller"
import BlanksController from "./widgets/blanks_controller"
import GridFillController from "./widgets/grid_fill_controller"
import GridShadeController from "./widgets/grid_shade_controller"
import CoordinatePlotController from "./widgets/coordinate_plot_controller"
import CategorizeController from "./widgets/categorize_controller"
import MatcherController from "./widgets/matcher_controller"
import AngleDialController from "./widgets/angle_dial_controller"
import ClockHandsController from "./widgets/clock_hands_controller"
import ColumnArithmeticController from "./widgets/column_arithmetic_controller"
import BalanceScaleController from "./widgets/balance_scale_controller"
import GeoboardController from "./widgets/geoboard_controller"
import UnitCircleController from "./widgets/unit_circle_controller"
import FindMistakeController from "./widgets/find_mistake_controller"
import NumberHopsController from "./widgets/number_hops_controller"
import InequalityLineController from "./widgets/inequality_line_controller"
import HintsController from "./hints_controller"
import ChallengeController from "./challenge_controller"
import MedalController from "./medal_controller"
import DisclosureController from "./disclosure_controller"
import SoundToggleController from "./sound_toggle_controller"
import SoundDemoController from "./sound_demo_controller"
import ChangelogController from "./changelog_controller"
import PollController from "./poll_controller"

const application = Application.start()
application.register("flash", FlashController)
application.register("menu", MenuController)
application.register("answer-form", AnswerFormController)
application.register("scroll-shadows", ScrollShadowsController)
application.register("question-form", QuestionFormController)
application.register("widget-number-line", NumberLineController)
application.register("widget-ordering", OrderingController)
application.register("widget-fraction-bars", FractionBarsController)
application.register("widget-multi-select", MultiSelectController)
application.register("widget-blanks", BlanksController)
application.register("widget-grid-fill", GridFillController)
application.register("widget-grid-shade", GridShadeController)
application.register("widget-coordinate-plot", CoordinatePlotController)
application.register("widget-categorize", CategorizeController)
application.register("widget-matcher", MatcherController)
application.register("widget-angle-dial", AngleDialController)
application.register("widget-clock-hands", ClockHandsController)
application.register("widget-column-arithmetic", ColumnArithmeticController)
application.register("widget-balance-scale", BalanceScaleController)
application.register("widget-geoboard", GeoboardController)
application.register("widget-unit-circle", UnitCircleController)
application.register("widget-find-mistake", FindMistakeController)
application.register("widget-number-hops", NumberHopsController)
application.register("widget-inequality-line", InequalityLineController)
application.register("hints", HintsController)
application.register("challenge", ChallengeController)
application.register("medal", MedalController)
application.register("disclosure", DisclosureController)
application.register("sound-toggle", SoundToggleController)
application.register("sound-demo", SoundDemoController)
application.register("changelog", ChangelogController)
application.register("poll", PollController)

// KaTeX, MathLive and Tiptap are most of the bundle's weight, and most pages
// use none of them: each of these is fetched the first time a page has an
// element that asks for it, and connects once it arrives.
registerLazy(application, {
  "math": () => import("./math_controller"),
  "math-input": () => import("./math_input_controller"),
  "editor": () => import("./editor_controller")
})
