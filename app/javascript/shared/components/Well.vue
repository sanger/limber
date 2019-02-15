<template>
  <div :class="['well', wellName]"><span v-if="poolIndex" :class="['aliquot', colourClass]">{{ tagIndex }}</span></div>
</template>

<script>
  export default {
    name: 'Well',
    props: {
      wellName: { type: String, default: null },
      poolIndex: { type: Number, default: null },
      tagIndex: { type: String, default: null }
    },
    computed: {
      colourClass() {
        if(this.tagIndex && this.tagIndex === 'X') { return `colour-172` }
        return `colour-${this.poolIndex}`
      }
    }
  }
</script>
