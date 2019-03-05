<template>
  <b-form-group :label="formLabel">
    <b-form-radio-group v-model="primerPanel"
                        :options="primerPanels"
                        size="lg">
    </b-form-radio-group>
  </b-form-group>
</template>

<script>
  export default {
    name: 'PrimerPanelFilter',
    data () {
      return {
        primerPanel: null
      }
    },
    props: {
      requestsWithPlates: { type: Array, required: true }
    },
    methods: {
      matchPrimerPanel(requestWithPlate) {
        return requestWithPlate.request.primer_panel.name === this.primerPanel
      }
    },
    computed: {
      primerPanels() { // Returns the mutual primer panels
        const primerPanelsByPlate = new Map()
        this.requestsWithPrimerPanel.forEach((requestWithPlate) => {
          const plate_id = requestWithPlate.plateObj.plate.id
          const primer_panel = requestWithPlate.request.primer_panel.name
          if (primerPanelsByPlate.has(plate_id)) {
            primerPanelsByPlate.get(plate_id).add(primer_panel)
          }
          else {
            primerPanelsByPlate.set(plate_id, new Set([primer_panel]))
          }
        })
        if (primerPanelsByPlate.size === 0) { return [] }
        const primerPanelsIterable =
          Array.from(primerPanelsByPlate.values()).reduce((accu, current) =>
            Array.from(accu.values()).filter(val => current.has(val)))
        return Array.from(primerPanelsIterable.values())
      },
      requestsWithPrimerPanel() {
        return this.requestsWithPlates.filter(requestWithPlate =>
            requestWithPlate.request.primer_panel)
      },
      formLabel() {
        let requests_len = this.requestsWithPrimerPanel.length
        let primer_panels_len = this.primerPanels.length
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
    }
  }
</script>
