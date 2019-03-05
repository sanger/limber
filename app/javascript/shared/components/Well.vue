<template>
  <div :class="['well', wellName]"><span v-if="poolIndex" :class="['aliquot', colourClass]" @click="onWellClicked">{{ tagIndex }}</span></div>
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
    },
    methods: {
      onWellClicked() {
        this.$emit('onwellclicked', this.wellName)
      }
    }
  }
</script>
