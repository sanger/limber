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
    tagIndex: { type: String, default: null },
    validity: { type: Object, default: () => { return { valid: true, message: '' }} }
  },
  computed: {
    colourClass() {
      return ((this.validity.valid) ? `colour-${this.pool_index}` : 'failed' )
    }
  },
  methods: {
    onWellClicked() {
      this.$emit('onwellclicked', this.position, this.validity )
    }
  }
}
</script>
