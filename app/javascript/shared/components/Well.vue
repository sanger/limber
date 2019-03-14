<template>
  <div :class="['well', position]">
    <span
      v-if="pool_index"
      :class="['aliquot', colourClass]"
      @click="onWellClicked"
    >{{ tagIndex }}</span>
  </div>
</template>

<script>
export default {
  name: 'Well',
  props: {
    position: { type: String, default: null },
    pool_index: { type: Number, default: null },
    tagIndex: { type: String, default: null }
  },
  computed: {
    colourClass() {
      if(this.tagIndex && this.tagIndex === 'X') { return 'colour-172' }
      return `colour-${this.pool_index}`
    }
  },
  methods: {
    onWellClicked() {
      this.$emit('onwellclicked', this.position)
    }
  }
}
</script>
