<template><span /></template>

<script>
export default {
  name: 'MultiStampTransfers',
  props: {
    validTransfers: { type: Array, required: true }
  },
  watch: {
    requestsWithPlates: function () {
      this.$emit('change', this.apiTransfers(this.validTransfers))
    }
  },
  methods: {
    apiTransfers(transfers) {
      const transfersArray = new Array(transfers.length)
      for (let i = 0; i < transfers.length; i++) {
        const transfer = transfers[i]
        transfersArray[i] = {
          source_plate: transfer.plateObj.plate.uuid,
          pool_index: transfer.plateObj.index + 1,
          source_asset: transfer.well.uuid,
          outer_request: transfer.request.uuid,
          new_target: { location: transfer.targetWell }
        }
      }
      return transfersArray
    }
  }
}
</script>
