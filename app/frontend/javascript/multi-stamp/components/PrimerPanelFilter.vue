<template>
  <b-form-group :label="formLabel">
    <b-form-radio-group v-model="primerPanel" :options="primerPanels" size="lg" />
  </b-form-group>
</template>

<script>
export default {
  name: 'PrimerPanelFilter',
  props: {
    requestsWithPlates: { type: Array, required: true },
  },
  emits: ['change'],
  data() {
    return {
      primerPanel: null,
    }
  },
  computed: {
    // Returns the mutual primer panels. Aggregates primer panel names by plate
    // using a Map of Arrays, then reduces each array (corresponding to
    // a single plate primer panle subset) returning only the primer panel
    // names found in every plate.
    primerPanels() {
      const primerPanelsByPlate = new Map()
      for (let i = 0; i < this.requestsWithPrimerPanel.length; i++) {
        const requestWithPlate = this.requestsWithPrimerPanel[i]
        const plate_id = requestWithPlate.plateObj.plate.id
        const primer_panel = requestWithPlate.request.primer_panel.name
        if (primerPanelsByPlate.has(plate_id)) {
          const primerPanelArray = primerPanelsByPlate.get(plate_id)
          if (!primerPanelArray.includes(primer_panel)) {
            primerPanelArray.push(primer_panel)
          }
        } else {
          primerPanelsByPlate.set(plate_id, [primer_panel])
        }
      }
      if (primerPanelsByPlate.size === 0) {
        return []
      }
      const primerPanelsIterable = Array.from(primerPanelsByPlate.values()).reduce((accu, current) =>
        accu.filter((val) => current.includes(val)),
      )
      return primerPanelsIterable
    },
    requestsWithPrimerPanel() {
      const requestsArray = []
      for (let i = 0; i < this.requestsWithPlates.length; i++) {
        if (this.requestsWithPlates[i].request.primer_panel) {
          requestsArray.push(this.requestsWithPlates[i])
        }
      }
      return requestsArray
    },
    formLabel() {
      const all_requests_len = this.requestsWithPlates.length
      const pp_requests_len = this.requestsWithPrimerPanel.length
      const primer_panels_len = this.primerPanels.length
      if (pp_requests_len !== 0 && primer_panels_len !== 0) {
        return 'Select a primer panel to process'
      } else if (pp_requests_len !== 0 && primer_panels_len === 0) {
        return 'No common primer panel found among scanned plates!'
      } else if (pp_requests_len === 0 && all_requests_len !== 0) {
        return 'No primer panel found among scanned plates.'
      } else {
        return ''
      }
    },
    // Filters out the requests that don't have the selected primer panel
    requestsWithPlatesFiltered() {
      const requestsArray = []
      for (let i = 0; i < this.requestsWithPrimerPanel.length; i++) {
        if (this.requestsWithPrimerPanel[i].request.primer_panel.name === this.primerPanel) {
          requestsArray.push(this.requestsWithPrimerPanel[i])
        }
      }
      return requestsArray
    },
  },
  watch: {
    requestsWithPlatesFiltered: function () {
      this.$emit('change', this.requestsWithPlatesFiltered)
    },
  },
}
</script>
