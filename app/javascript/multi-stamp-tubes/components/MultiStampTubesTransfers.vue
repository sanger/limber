<template><span /></template>

<script>
export default {
  name: 'MultiStampTubesTransfers',
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
