<template><span /></template>

<script>
// Keeps only the requests of the given request types, so that other active
// requests on the source wells are not transferred. For example, pending
// Illumina multiplexing requests on an XP plate that is aggregated for the
// Ultima conversion. Without it, a well with two active requests could not be
// transferred.
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
