<template><span /></template>

<script>
export default {
  name: 'MultiStampTubesTransfers',
  props: {
    validTransfers: { type: Array, required: true },
  },
  emits: ['update:model-value'],
  watch: {
    validTransfers: function () {
      this.$emit('update:model-value', {
        extraParams: (_transfer) => {},
        isValid: true,
      })
    },
  },
}
</script>
