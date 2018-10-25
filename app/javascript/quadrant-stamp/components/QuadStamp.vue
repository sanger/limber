<template>
  <lb-page>
    <lb-main-content>
      <b-card bg-variant="dark" text-variant="white">
        <lb-plate caption="New Plate" :rows="targetRows" :columns="targetColumns"></lb-plate>
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card header="Add plates" header-tag="h3">
        <p class="card-text">Scan in the plates you wish to use.</p>
        <lb-plate-scan v-for="i in sourcePlateNumber"
                       :plate-api="Api.Plate"
                       :label="'Plate ' + i"
                       :key="i"
                       :includes="{wells: ['requests_as_source',{aliquots: 'request'}]}"
                       v-on:change="updatePlate(i, $event)"></lb-plate-scan>
      </b-card>
    </lb-sidebar>
    <b-alert>{{ transfers }}</b-alert>
  </lb-page>
</template>

<style lang="scss" scoped>
</style>

<script>

  import Plate from 'shared/components/Plate'
  import PlateScan from 'shared/components/PlateScan'
  import ApiModule from 'shared/api'

  export default {
    name: 'QuadStamp',
    data () {
      let plateArray = Array(this.sourcePlateNumber)
      plateArray.fill({ state: 'empty', plate: null })

      return {
        Api: ApiModule({ baseUrl: this.sequencescapeApi }),
        plates: plateArray
      }
    },
    props: {
      sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
      targetRows: { type: Number, default: 16 },
      targetColumns: { type: Number, default: 24 },
      sourcePlateNumber: { type: Number, default: 4 }
    },
    methods: {
      updatePlate(index, data) {
        this.$set(this.plates, index - 1, data)
      }
    },
    computed: {
      transfers() {
        let transferArray = []
        this.plates.forEach(function(plate, index){
          if (plate.state !== 'valid') { return } // We only process valid plates
          console.log(plate, index)
        })
        return transferArray
      }
    },
    components: {
      'lb-plate': Plate,
      'lb-plate-scan': PlateScan
    }
  }
</script>
