let Hooks = {};

import EditorJS from "../vendor/editorjs@latest"


Hooks.EditorJS = {
  mounted() {
    const json = JSON.parse(this.el.dataset.content);
    let data = {};
    
    if(json) {
      data = json.content;
    }

    this.editor = new EditorJS({data: data});

    this.handleEvent('save', (product) => {
      this.editor.save().then((outputData) => {
        this.pushEvent("save-content", {content: outputData}, (reply) => {
          console.debug(reply.message);
        });

        console.log('Article data: ', outputData)
      }).catch((error) => {
        console.log('Saving failed: ', error)
      });
    })
  },

  destroyed() {
    if (this.editor) {
      this.editor = null;
    }
  }
}

export default Hooks;
