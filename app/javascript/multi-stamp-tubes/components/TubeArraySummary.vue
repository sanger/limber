<template>
  <table id="tube_scan_summary" :class="['plate-view', 'pool-colours']">
    <caption>
      {{
        'Summary of tubes scanned into the rack'
      }}
    </caption>
    <thead>
      <tr>
        <th class="first-col" />
        <th id="header_human_barcode" class="headingcell">Human Barcode</th>
        <th id="header_machine_barcode" class="headingcell">Machine Barcode</th>
        <th id="header_replicates" class="headingcell">Replicates</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="(row, rowIndex) in tubeSummary" :key="row.barcode">
        <th class="first-col">
          {{ (rowIndex + 1).toString() + '.' }}
        </th>
        <td :id="`row_human_barcode_index_${rowIndex}`" class="summarycell">
          {{ row.human_barcode }}
        </td>
        <td :id="`row_machine_barcode_index_${rowIndex}`" class="summarycell">
          {{ row.machine_barcode }}
        </td>
        <td :id="`row_replicates_index_${rowIndex}`" class="replicate_cell">
          {{ row.replicates }}
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>
export default {
  name: 'TubeArraySummary',
  props: {
    tubes: {
      type: Array,
      required: true,
    },
  },
  computed: {
    tubesDict() {
      var summary_dict = {}
      this.tubes.forEach(function (tube) {
        var tube_machine_barcode = 'Empty'
        var tube_human_barcode = 'Empty'

        // skip empty locations
        if (tube.labware != null) {
          tube_machine_barcode = tube.labware.labware_barcode.machine_barcode
          tube_human_barcode = tube.labware.labware_barcode.human_barcode
        }

        // add to dict of summary counts
        if (tube_machine_barcode in summary_dict) {
          summary_dict[tube_machine_barcode]['replicates'] += 1
        } else {
          summary_dict[tube_machine_barcode] = {
            replicates: 1,
            human_barcode: tube_human_barcode,
          }
        }
      })
      return summary_dict
    },
    tubeSummary() {
      var summary_array = []
      for (var tube_barcode in this.tubesDict) {
        summary_array.push({
          machine_barcode: tube_barcode,
          human_barcode: this.tubesDict[tube_barcode]['human_barcode'],
          replicates: this.tubesDict[tube_barcode]['replicates'],
        })
      }
      return summary_array
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
.replicate_cell {
  margin-top: 2px;
  text-align: right;
  padding: 4px;
}
</style>
