<template>
  <div
    v-if="isEmpty"
    class="no-tube tube-summary"
  >
    <div class="well">
      &nbsp;
    </div> No tube
  </div>
  <div
    v-else
    :class="['a-tube','tube-summary','pool-colours',state]"
  >
    <div class="well">
      <span :class="['aliquot', colourClass]" />
    </div>{{ barcode }}
  </div>
</template>


<script>
export default {
  name: 'TubeSummary',
  props: {
    pool_index: { default: null, type: Number },
    state: { default: 'empty', type: String },
    tube: {
      default() { return  { labware_barcode: { human_barcode: '...' } } },
      type: Object
    }
  },
  computed: {
    colourClass() {
      return `colour-${this.pool_index}`
    },
    isEmpty() {
      return this.tube === null
    },
    barcode() {
      if (this.tube) {
        return this.tube.labware_barcode.human_barcode
      } else {
        return ''
      }
    }
  }
}
</script>

<style scoped lang="scss">
  .tube-summary {
    width: 20%;
    margin: 0 2% 10px 2%;
    display: inline-block;
    padding: 5px;
    border-radius: 0px 15px 15px 0px;
  }
  .no-tube {
    border: 1px solid white;
    .well { background: #343a40; }
  }
  .a-tube {
    // Work out how to get the import working correctly
    background-color: #6c757d; // $gray-600
    border: 1px solid #6c757d;
    .well { background: #e9ecef; }
  }
  .a-tube.duplicate, .a-tube.invalid {
    background-color: #d9534f;
    border: 1px solid #ee1111;
  }
  .well {
    height:30px;
    width:30px;
    margin-right: 5px;
    text-align: center;
    overflow: hidden;
    display: inline-block;
    vertical-align: middle;

    .aliquot {
      width:26px;
      height:26px;
      margin-top: 2px;
      text-align: center;
      display: inline-block;
      border: 2px #343a40 solid;
      border-radius: 7px;
    }
  }
</style>
