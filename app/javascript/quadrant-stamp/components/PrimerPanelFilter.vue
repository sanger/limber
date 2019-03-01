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
        let primerPanelsByPlate = new Map()
        this.requestsWithPrimerPanel.forEach((requestWithPlate) => {
          let plate_uuid = requestWithPlate.plateObj.plate.uuid
          let primer_panel = requestWithPlate.request.primer_panel.name
          if (primerPanelsByPlate.has(plate_uuid)) {
            primerPanelsByPlate.get(plate_uuid).add(primer_panel)
          }
          else {
            primerPanelsByPlate.set(plate_uuid, new Set([primer_panel]))
          }
        })
        if (primerPanelsByPlate.size === 0) { return [] }
        let primerPanelsIterable =
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
      filteredRequests() {
        return this.requestsWithPrimerPanel.filter((requestWithPlate) =>
          this.matchPrimerPanel(requestWithPlate))
      }
    },
    watch: {
      primerPanel: function() {
        this.$emit('change', this.filteredRequests)
      }
    }
  }
</script>
