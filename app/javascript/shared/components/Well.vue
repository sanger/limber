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
    pool_index: { default: null, type: Number }
  },
  computed: {
    colourClass() {
      return `colour-${this.pool_index}`
    }
  }
}
</script>
