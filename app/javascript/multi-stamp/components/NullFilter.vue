<template><span /></template>

<script>
export default {
  name: 'NullFilter',
  props: {
    requestsWithPlates: { type: Array, required: true },
  },
  watch: {
    requestsWithPlates: function () {
      this.$emit('change', this.requestsWithPlates)
    },
  },
}
</script>
