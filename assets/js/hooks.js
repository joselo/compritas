let Hooks = {};

import * as echarts from "../vendor/echarts.min"

Hooks.Echart = {
  render(chart, option) {
    if (chart.getOption() && option.legend && option.legend.selected) {
      delete option.legend.selected
    }

    chart.setOption(option)
  },

  mounted() {
    let chart = echarts.init(this.el)

    this.handleEvent(`chart-option-${this.el.id}`, (option) =>
      this.render(chart, option)
    )
  }
};

export default Hooks;
