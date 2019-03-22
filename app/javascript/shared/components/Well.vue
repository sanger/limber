<template>
  <div :class="['well', position]">
    <span
      v-if="pool_index"
      :class="['aliquot', colourClass, linethroughClass]"
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
    tagIndex: { type: Number, default: null },
    validity: { type: Object, default: () => { return { valid: true, message: '' }} }
  },
  computed: {
    colourClass() {
      return ((this.validity.valid) ? `colour-${this.pool_index}` : 'failed' )
    },
    linethroughClass() {
      return ((this.validity.valid) ? '' : 'line-through' )
    }
  },
  methods: {
    onWellClicked() {
      this.$emit('onwellclicked', this.position )
    }
  }
}
</script>

<style scoped>
  .line-through {
    text-decoration: line-through;
  }
</style>