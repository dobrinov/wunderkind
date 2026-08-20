import { Controller } from "@hotwired/stimulus"
import { Editor, Node } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import katex from "katex"
import { MathfieldElement } from "mathlive"

// Inline LaTeX node. Rendered with KaTeX; edited via a MathLive popover.
const MathNode = Node.create({
  name: "math",
  group: "inline",
  inline: true,
  atom: true,

  addAttributes() {
    return { latex: { default: "" } }
  },

  parseHTML() {
    return [{ tag: "span[data-math]" }]
  },

  renderHTML({ node }) {
    return ["span", { "data-math": "", "data-latex": node.attrs.latex }, node.attrs.latex]
  },

  addNodeView() {
    return ({ node, getPos, editor }) => {
      const dom = document.createElement("span")
      dom.className = "mx-0.5 rounded px-1 py-0.5 bg-[var(--color-accent-soft)] cursor-pointer"
      try {
        katex.render(node.attrs.latex, dom, { throwOnError: false })
      } catch {
        dom.textContent = node.attrs.latex
      }
      dom.addEventListener("click", () => {
        editor.options.element.dispatchEvent(
          new CustomEvent("math:edit", { bubbles: true, detail: { pos: getPos(), latex: node.attrs.latex } })
        )
      })
      return { dom }
    }
  }
})

// The authoring editor: rich text + inline math, serialized to the same
// restricted JSON document the server renders.
export default class extends Controller {
  static targets = ["mount", "hidden", "popover", "boldButton", "italicButton"]
  static values = { content: Object }

  connect() {
    this.editor = new Editor({
      element: this.mountTarget,
      extensions: [
        StarterKit.configure({
          heading: false,
          bulletList: false,
          orderedList: false,
          listItem: false,
          blockquote: false,
          codeBlock: false,
          code: false,
          strike: false,
          horizontalRule: false,
          link: false,
          underline: false
        }),
        MathNode
      ],
      content: Object.keys(this.contentValue).length ? this.contentValue : "",
      editorProps: {
        attributes: { class: "prose-editor min-h-32 px-3 py-2 focus:outline-none" }
      },
      onUpdate: () => this.sync(),
      onSelectionUpdate: () => this.updateToolbar()
    })

    this.element.addEventListener("math:edit", (event) => this.openPopover(event.detail))
    this.form = this.element.closest("form")
    this.onSubmit = () => this.sync()
    this.form?.addEventListener("submit", this.onSubmit)
    this.sync()
  }

  disconnect() {
    this.form?.removeEventListener("submit", this.onSubmit)
    this.editor?.destroy()
  }

  sync() {
    this.hiddenTarget.value = JSON.stringify(this.editor.getJSON())
  }

  bold() {
    this.editor.chain().focus().toggleBold().run()
    this.updateToolbar()
  }

  italic() {
    this.editor.chain().focus().toggleItalic().run()
    this.updateToolbar()
  }

  insertMath() {
    this.openPopover({ pos: null, latex: "" })
  }

  updateToolbar() {
    this.boldButtonTarget.classList.toggle("editor-button-active", this.editor.isActive("bold"))
    this.italicButtonTarget.classList.toggle("editor-button-active", this.editor.isActive("italic"))
  }

  openPopover({ pos, latex }) {
    this.closePopover()
    this.editingPos = pos

    this.mathfield = new MathfieldElement()
    MathfieldElement.fontsDirectory = "/mathlive-fonts"
    MathfieldElement.soundsDirectory = null
    this.mathfield.value = latex
    this.mathfield.style.minWidth = "12rem"
    this.popoverTarget.querySelector("[data-slot=field]").replaceChildren(this.mathfield)
    this.popoverTarget.classList.remove("hidden")
    this.mathfield.focus()

    this.mathfield.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        event.preventDefault()
        this.confirmMath()
      }
      if (event.key === "Escape") this.closePopover()
    })
  }

  confirmMath() {
    const latex = this.mathfield.getValue("latex")
    if (latex.trim() !== "") {
      if (this.editingPos === null) {
        this.editor.chain().focus().insertContent({ type: "math", attrs: { latex } }).run()
      } else {
        const pos = this.editingPos
        this.editor
          .chain()
          .focus()
          .command(({ tr, state }) => {
            tr.setNodeMarkup(pos, state.schema.nodes.math, { latex })
            return true
          })
          .run()
      }
    }
    this.closePopover()
    this.sync()
  }

  closePopover() {
    this.popoverTarget.classList.add("hidden")
    this.mathfield?.remove()
    this.mathfield = null
  }
}
