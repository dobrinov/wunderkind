import { Application } from "@hotwired/stimulus"

import MathController from "./math_controller"
import MathInputController from "./math_input_controller"
import FlashController from "./flash_controller"
import MenuController from "./menu_controller"
import AnswerFormController from "./answer_form_controller"
import ScrollShadowsController from "./scroll_shadows_controller"
import EditorController from "./editor_controller"
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
import HintsController from "./hints_controller"
import ChallengeController from "./challenge_controller"
import BadgesController from "./badges_controller"
import DisclosureController from "./disclosure_controller"
import ClipboardController from "./clipboard_controller"

const application = Application.start()
application.register("math", MathController)
application.register("math-input", MathInputController)
application.register("flash", FlashController)
application.register("menu", MenuController)
application.register("answer-form", AnswerFormController)
application.register("scroll-shadows", ScrollShadowsController)
application.register("editor", EditorController)
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
application.register("hints", HintsController)
application.register("challenge", ChallengeController)
application.register("badges", BadgesController)
application.register("disclosure", DisclosureController)
application.register("clipboard", ClipboardController)
