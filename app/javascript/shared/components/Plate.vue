<template>
  <table id="plate" :class="['plate-view', sizeClass, 'pool-colours']">
    <caption>
      {{
        caption
      }}
    </caption>
    <thead>
      <tr>
        <th class="first-col" />
        <th v-for="column in columns" :key="column">
          {{ column }}
        </th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="row in rows" :key="row">
        <th class="first-col">
          {{ row | toLetter }}
        </th>
        <td v-for="column in columns" :key="column">
          <lb-well v-bind="wellAt(row, column)" @onwellclicked="onWellClicked" />
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>
import Well from 'shared/components/Well'
import { rowNumToLetter } from 'shared/wellHelpers'

export default {
  name: 'Plate',
  filters: {
    toLetter: rowNumToLetter,
  },
  components: {
    'lb-well': Well,
  },
  props: {
    columns: { type: Number, default: 12 },
    rows: { type: Number, default: 8 },
    caption: { type: String, default: '' },
    wells: {
      type: Object,
      default: () => {
        return {}
      },
    },
  },
  computed: {
    sizeClass: function () {
      return 'plate-' + this.columns * this.rows
    },
  },
  methods: {
    wellAt: function (row, column) {
      return this.wells[`${rowNumToLetter(row)}${column}`] || {}
    },
    onWellClicked(position) {
      this.$emit('onwellclicked', position)
    },
  },
}
</script>
