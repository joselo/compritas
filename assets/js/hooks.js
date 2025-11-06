let Hooks = {};

import EditorJS from "../vendor/editorjs@latest"


Hooks.EditorJS = {
  mounted() {
    this.editor = new EditorJS();

    // this.editor = new SimpleMDE({ 
    //   element: this.el,
    //   spellChecker: false,
    // });
    // 
    // this.editor.codemirror.on("change", () => {
    //   this.el.value = this.editor.value();
    //   // this.el.dispatchEvent(new Event('input', { bubbles: true }));
    // });

    this.handleEvent('save', (product) => {
      this.editor.save().then((outputData) => {
        console.log('Article data: ', outputData)
      }).catch((error) => {
        console.log('Saving failed: ', error)
      });
    })
  },

  updated() {
    // const newValue = this.el.value;
    //
    // if (this.editor.value() !== newValue) {
    //   this.editor.value(newValue);
    // }
   },
  
  destroyed() {
    // if (this.editor) {
    //   this.editor.toTextArea();
    //   this.editor = null;
    // }
  }
}

export default Hooks;
