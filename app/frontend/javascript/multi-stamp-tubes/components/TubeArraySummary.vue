<template>
  <table id="tube_scan_summary" :class="['plate-view', 'pool-colours']">
    <caption>
      {{
        'Summary of scanned tubes'
      }}
    </caption>
    <thead>
      <tr>
        <th class="first-col" />
        <th id="header_tube_colour" class="headingcell">Tube Colour</th>
        <th id="header_human_barcode" class="headingcell">Human Barcode</th>
        <th id="header_machine_barcode" class="headingcell">Machine Barcode</th>
        <th id="header_replicates" class="headingcell">Replicates</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="(summary, machine_barcode, rowIndex) in tubesDict" :key="rowIndex">
        <th class="first-col">
          {{ (rowIndex + 1).toString() + '.' }}
        </th>
        <td :id="`row_tube_colour_index_${rowIndex}`" class="tube_colour_cell">
          <div v-if="summary.well_colour" :class="['aliquot', `colour-${summary.well_colour}`]"></div>
        </td>
        <td :id="`row_human_barcode_index_${rowIndex}`" class="summarycell">
          {{ summary.human_barcode }}
        </td>
        <td :id="`row_machine_barcode_index_${rowIndex}`" class="summarycell">
          {{ machine_barcode }}
        </td>
        <td :id="`row_replicates_index_${rowIndex}`" class="replicate_cell">
          {{ summary.replicates }}
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>
import { findUniqueIndex } from '@/javascript/shared/wellHelpers.js'

export default {
  name: 'TubeArraySummary',
  props: {
    // See parent component MultiStampTubes for more details about the Lab process.
    // This prop is the array of tube objects from the parent component, it represents the tubes
    // scanned into the MultiStampTubes arraying component. It gets updated every time there is
    // a change to the tubes in the parent component.
    //
    // Each tube object contains the following:
    //  - index: the index of the tube in the array, related to the position in the tube rack
    //  - labware: the labware object scanned into the parent screen, null if position is empty, here
    //    we are most interested in the barcodes of the labware
    //  - state: the state of the tube at this index, or 'empty' if nothing scanned yet
    tubes: {
      type: Array,
      required: true,
    },
  },
  computed: {
    // Create a dictionary of tube barcodes and their numbers of replicates for use
    // in the summary table
    tubesDict() {
      var summary_dict = {}
      const machine_barcodes = this.tubes.reduce((acc, tube) => {
        if (tube.labware && tube.labware.state == 'passed') {
          acc.push(tube.labware.labware_barcode.machine_barcode)
        }
        return acc
      }, [])

      this.tubes.forEach(function (tube) {
        var tube_machine_barcode = 'Empty'
        var tube_human_barcode = 'Empty'

        // extract the labware barcodes where the labware has been scanned
        if (tube.labware != null) {
          tube_machine_barcode = tube.labware.labware_barcode.machine_barcode
          tube_human_barcode = tube.labware.labware_barcode.human_barcode
        }

        // determine the colour of the tube
        let colour_index = null
        if (tube.labware != null) {
          const barcode_index = findUniqueIndex(machine_barcodes, tube_machine_barcode)
          if (barcode_index !== -1) colour_index = barcode_index + 1
        }

        // build up the dictionary of summary table replicates by barcode (and empties)
        if (tube_machine_barcode in summary_dict) {
          summary_dict[tube_machine_barcode]['replicates'] += 1
        } else {
          summary_dict[tube_machine_barcode] = {
            replicates: 1,
            human_barcode: tube_human_barcode,
            well_colour: colour_index,
          }
        }
      })
      return summary_dict
    },
  },
}
</script>

<style scoped lang="scss">
.headingcell {
  margin-top: 2px;
  text-align: left;
  padding: 4px;
  border: 1px #343a40 solid;
  border-radius: 2px;
}
.summarycell {
  margin-top: 2px;
  text-align: left;
  padding: 4px;
}
.tube_colour_cell {
  @extend .summarycell;
  text-align: center;
}
.aliquot {
  width: 24px;
  height: 24px;
  margin-top: 2px;
  text-align: center;
  display: inline-block;
  border: 2px #343a40 solid;
  border-radius: 7px;
}
.replicate_cell {
  margin-top: 2px;
  text-align: right;
  padding: 4px;
}
</style>
