<template><span /></template>

<script>
export default {
  name: 'BlendedTubeTransfers',
  props: {
    validTransfers: { type: Array, required: true },
  },
  watch: {
    validTransfers: function () {
      this.$emit('change', {
        extraParams: (_transfer) => {},
        isValid: true,
      })
    },
  },
}
</script>
