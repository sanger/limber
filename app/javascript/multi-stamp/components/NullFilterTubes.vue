<template><span /></template>

<script>

export default {
  name: 'NullFilter',
  props: {
    requestsWithTubes: { type: Array, required: true }
  },
  watch: {
    requestsWithTubes: function () {
      this.$emit('change', this.requestsWithTubes)
    }
  }
}
</script>
