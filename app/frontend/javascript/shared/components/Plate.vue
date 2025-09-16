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
          {{ rowHeader(row) }}
        </th>
        <td v-for="column in columns" :key="column">
          <lb-well
            v-bind="wellAt(row, column)"
            :tooltip_label="tooltip_label(row, column)"
            :position="position(row, column)"
            @onwellclicked="onWellClicked"
          />
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>
import LbWell from '@/javascript/shared/components/Well.vue'
import { rowNumToLetter } from '@/javascript/shared/wellHelpers.js'

export default {
  name: 'LbPlate',
  components: {
    'lb-well': LbWell,
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
  emits: ['onwellclicked'],
  computed: {
    sizeClass: function () {
      return 'plate-' + this.columns * this.rows
    },
  },
  methods: {
    rowHeader(row) {
      return rowNumToLetter(row)
    },
    tooltip_label: function (row, column) {
      return this.wellAt(row, column).human_barcode
    },
    position: function (row, column) {
      return `${rowNumToLetter(row)}${column}`
    },
    wellAt: function (row, column) {
      return this.wells[`${rowNumToLetter(row)}${column}`] || {}
    },
    onWellClicked(position) {
      this.$emit('onwellclicked', position)
    },
  },
}
</script>
