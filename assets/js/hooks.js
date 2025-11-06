let Hooks = {};

import EditorJS from "../vendor/editorjs@latest"
import Table from "../vendor/table@latest"
import EditorjsList from "../vendor/list@2"
import ImageTool from '../vendor/image@latest'

Hooks.EditorJS = {
  mounted() {
    const json = JSON.parse(this.el.dataset.content);
    let data = {};
    
    if (json) {
      data = json.content;
    }

    const tools = {
      table: {
        class: Table,
        inlineToolbar: true,
        config: {
          i18n: {
            "Add column to left": "Agregar columna a la izquierda",
            "Add column to right": "Agregar columna a la derecha",
            "Add row above": "Agregar fila arriba",
            "Add row below": "Agregar fila abajo",
            "Delete column": "Eliminar columna",
            "Delete row": "Eliminar fila",
          },
        },
      },
      list: {
        class: EditorjsList,
        inlineToolbar: true,
        config: {
          defaultStyle: "unordered",
        },
      },
      image: {
        class: ImageTool,
        config: {
          endpoints: {
            byFile: '/uploadFile',
            byUrl: '/fetchUrl',
          }
        }
      }
    };

    const i18n = {
      messages: {
        ui: {
          blockTunes: {
            toggler: {
              "Click to tune": "Haz clic para ajustar",
              "or drag to move": "o arrastra para mover",
            },
          },
          toolbar: {
            toolbox: {
              "Add": "Agregar bloque",
            },
          },
        },
        toolNames: {
          Text: "Texto",
          List: "Lista",
          Table: "Tabla",
        },
        tools: {
          list: {
            "Ordered": "Lista numerada",
            "Unordered": "Lista con viñetas",
            "Checklist": "Lista de tareas",
          },
          table: {
            "With headings": "Con encabezados",
            "Without headings": "Sin encabezados",
          },
        },
        blockTunes: {
          delete: {
            "Delete": "Eliminar",
          },
          moveUp: {
            "Move up": "Mover arriba",
          },
          moveDown: {
            "Move down": "Mover abajo",
          },
        },
      },
    };

    this.editor = new EditorJS({
      holder: this.el.id,
      data: data,
      tools: tools,
      i18n: i18n,
      autofocus: true,
    });

    this.handleEvent("save", (_product) => {
      this.editor
        .save()
        .then((outputData) => {
          this.pushEvent("save-content", { content: outputData }, (reply) => {
            console.debug(reply.message);
          });
          console.log("Article data: ", outputData);
        })
        .catch((error) => {
          console.log("Saving failed: ", error);
        });
    });
  },

  destroyed() {
    if (this.editor) {
      this.editor = null;
    }
  },
};

export default Hooks;

