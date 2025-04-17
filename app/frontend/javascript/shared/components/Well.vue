<template>
  <div :id="wellId" :class="['well', position]">
    <div
      v-if="colour_index"
      :id="'aliquot_' + position"
      v-b-tooltip.hover="tooltipText"
      :class="['aliquot', colourClass]"
    >
      <span :class="[linethroughClass, 'tag']" @click="onWellClicked">{{ tagMapIdDisplay() }}</span>
    </div>
  </div>
</template>

<script>
// TODO: Why did we need to import it here separately?
// import Vue from 'vue'
// import BootstrapVue from 'bootstrap-vue'

// Vue.use(BootstrapVue)

export default {
  name: 'LbWell',
  props: {
    position: { type: String, required: true },
    colour_index: { type: Number, required: true },
    tooltip_label: { type: String, default: null },
    tagMapIds: {
      type: Array,
      default: () => {
        return []
      },
    },
    validity: {
      type: Object,
      default: () => {
        return { valid: true, message: '' }
      },
    },
  },
  emits: ['onwellclicked'],
  data() {
    return {
      tagIndex: 0,
    }
  },
  computed: {
    wellId() {
      return `well_${this.position}`
    },
    colourClass() {
      return this.validity.valid ? `colour-${this.colour_index}` : 'failed'
    },
    linethroughClass() {
      return this.validity.valid ? '' : 'line-through'
    },
    tooltipText() {
      if (this.tooltip_label) {
        return `${this.position} - ${this.tooltip_label}`
      } else {
        return this.position
      }
    },
  },
  created: function () {
    setInterval(this.updateTag, 1000)
  },
  methods: {
    onWellClicked() {
      this.$emit('onwellclicked', this.position)
    },
    tagMapIdDisplay() {
      if (this.tagMapIds.length === 0) {
        return ''
      } else {
        const tagMapId = this.tagMapIds[this.tagIndex]
        return tagMapId === -1 ? 'x' : tagMapId
      }
    },
    updateTag() {
      // We modulo this to ensure it goes 0,1,2,3,0,1,2,3
      if (this.tagMapIds.length === 0) {
        this.tagIndex = 0
      } else {
        this.tagIndex = (this.tagIndex + 1) % this.tagMapIds.length
      }
    },
  },
}
</script>

<style scoped>
.line-through {
  text-decoration: line-through;
}

.tag {
  display: none;
}

.tag:first-child {
  display: inline;
}
</style>
