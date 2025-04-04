<template><span /></template>

<script>
export default {
  name: 'MultiStampTransfers',
  props: {
    validTransfers: { type: Array, required: true },
  },
  emits: ['change'],
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
