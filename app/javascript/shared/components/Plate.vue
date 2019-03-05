<template>
  <table v-bind:class="['plate-view', sizeClass, 'pool-colours']">
    <caption>{{ caption }}</caption>
    <thead>
      <tr>
        <th class="first-col"></th>
        <th v-for="column in columns">{{ column }}</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="row in rows">
        <th class="first-col">{{ row | toLetter }}</th>
        <td v-for="column in columns">
          <lb-well :well-name="wellName(row - 1, column - 1)" v-bind="wellAt(row - 1, column - 1)" @onwellclicked="onWellClicked"></lb-well>
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>

  import Well from 'shared/components/Well'
  import { wellCoordinateToName, rowNumToLetter } from 'shared/wellHelpers'

  export default {
    name: 'Plate',
    props: {
      columns: { type: Number, default: 12 },
      rows: { type: Number, default: 8 },
      caption: { type: String },
      wells: { type: Object, default: () => { return {} } }
    },
    computed: {
      sizeClass: function () { return 'plate-' + (this.columns * this.rows) }
    },
    filters: {
      toLetter: rowNumToLetter
    },
    methods: {
      wellAt: function (row, column) {
        return this.wells[wellCoordinateToName([column, row])] || {}
      },
      wellName: function (row, column) {
        return wellCoordinateToName([column, row])
      },
      onWellClicked(wellName) {
        console.log('Plate got a click event from well ', wellName)
        this.$emit('onwellclicked', wellName)
      }
    },
    components: {
      'lb-well': Well
    }
  }
</script>
