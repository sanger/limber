<template>
  <div :class="['well', wellName]"><span v-if="pool_index" :class="['aliquot', colourClass]">{{ tagIndex }}</span></div>
</template>

<script>
  export default {
    name: 'Well',
    props: {
      wellName: { default: null },
      pool_index: { default: null },
      tagIndex: { default: null }
    },
    computed: {
      colourClass() {
        return `colour-${this.pool_index}`
      }
    }
  }
</script>
