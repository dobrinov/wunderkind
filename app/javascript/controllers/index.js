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
import HintsController from "./hints_controller"
import AssistController from "./assist_controller"

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
application.register("hints", HintsController)
application.register("assist", AssistController)
