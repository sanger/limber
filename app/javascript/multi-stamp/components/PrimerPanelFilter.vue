<template>
  <b-form-group :label="formLabel">
    <b-form-radio-group
      v-model="primerPanel"
      :options="primerPanels"
      size="lg"
    />
  </b-form-group>
</template>

<script>
export default {
  name: 'PrimerPanelFilter',
  props: {
    requestsWithPlates: { type: Array, required: true }
  },
  data () {
    return {
      primerPanel: null
    }
  },
  computed: {
    primerPanels() { // Returns the mutual primer panels
      const primerPanelsByPlate = new Map()
      for (let i = 0; i < this.requestsWithPrimerPanel.length; i++) {
        let requestWithPlate = this.requestsWithPrimerPanel[i]
        let plate_id = requestWithPlate.plateObj.plate.id
        let primer_panel = requestWithPlate.request.primer_panel.name
        if (primerPanelsByPlate.has(plate_id)) {
          let primerPanelArray = primerPanelsByPlate.get(plate_id)
          if (!primerPanelArray.includes(primer_panel)) {
            primerPanelArray.push(primer_panel)
          }
        }
        else {
          primerPanelsByPlate.set(plate_id, [primer_panel])
        }
      }
      if (primerPanelsByPlate.size === 0) { return [] }
      const primerPanelsIterable =
          Array.from(primerPanelsByPlate.values()).reduce((accu, current) =>
            accu.filter(val => current.includes(val)))
      return primerPanelsIterable
    },
    requestsWithPrimerPanel() {
      return this.requestsWithPlates.filter(requestWithPlate =>
        requestWithPlate.request.primer_panel)
    },
    formLabel() {
      const requests_len = this.requestsWithPrimerPanel.length
      const primer_panels_len = this.primerPanels.length
      if (requests_len !== 0 && primer_panels_len !== 0) {
        return 'Select a primer panel to process'
      }
      else if (requests_len !== 0 && primer_panels_len === 0) {
        return 'No common primer panel found among scanned plates!'
      }
      else {
        return ''
      }
    },
    requestsWithPlatesFiltered() {
      return this.requestsWithPrimerPanel.filter(this.matchPrimerPanel)
    }
  },
  watch: {
    requestsWithPlatesFiltered: function() {
      this.$emit('change', this.requestsWithPlatesFiltered)
    }
  },
  methods: {
    matchPrimerPanel(requestWithPlate) {
      return requestWithPlate.request.primer_panel.name === this.primerPanel
    }
  }
}
</script>
