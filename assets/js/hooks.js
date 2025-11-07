let Hooks = {};

Hooks.Gallery = {
  mounted() {
    console.log("gallery")
    // const json = JSON.parse(this.el.dataset.content);
  },

  destroyed() {
  },
};

export default Hooks;
