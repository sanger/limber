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
          <lb-well v-bind="wellAt(row, column)"></lb-well>
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>

  import Well from 'shared/components/Well'

  const rowNumToLetter = function (value) {
        return String.fromCharCode(value + 64)
      }

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
        return this.wells[`${rowNumToLetter(row)}${column}`] || {}
      }
    },
    components: {
      'lb-well': Well
    }
  }
</script>
