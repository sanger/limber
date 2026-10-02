<template><span /></template>

<script>
// Keeps only the requests of the given request types. Each kept request is a
// transfer of its well; the other active requests on the wells are ignored.
// For example, a well of an XP plate with an aggregation request and a pending
// Illumina multiplexing request is transferred once, for the aggregation
// request. Wells without a request of the given types are not transferred.
// Without the filter, both requests count, and the well is reported as having
// multiple transfers.
export default {
  name: 'RequestTypeFilter',
  props: {
    requestsWithPlates: { type: Array, required: true },
    // Keys of the request types to keep, e.g. ['limber_ultima_ltp_aggregation']
    requestTypeKeys: { type: Array, required: true },
  },
  emits: ['change'],
  computed: {
    requestsWithPlatesFiltered() {
      return this.requestsWithPlates.filter(({ request }) => this.requestTypeKeys.includes(request.request_type?.key))
    },
  },
  watch: {
    requestsWithPlatesFiltered: function () {
      this.$emit('change', this.requestsWithPlatesFiltered)
    },
  },
}
</script>
