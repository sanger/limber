<template>
  <div class="well">
    <span
      v-if="pool_index"
      :class="['aliquot', colourClass]"
    />
  </div>
</template>

<script>
export default {
  name: 'Well',
  props: {
    poolIndex: { default: null }
  },
  computed: {
    colourClass() {
      return `colour-${this.pool_index}`
    }
  }
}
</script>
