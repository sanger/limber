<template>
  <lb-page>
    <lb-main-content>
      <div class="alert alert-info">
        <h2>Debug properties:</h2>
        {{ _props }}
      </div>
      <b-card bg-variant="dark" text-variant="white">
        <lb-plate caption="New Plate" :rows="targetRows" :columns="targetColumns"></lb-plate>
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card header="Add plates" header-tag="h3">
        <p class="card-text">Scan in the plates you wish to use.</p>
      </b-card>
    </lb-sidebar>
  </lb-page>
</template>

<script>

  import Plate from 'shared/components/Plate'

  import ApiModule from 'shared/api'

  const Api = ApiModule('test')

  export default {
    name: 'QuadStamp',
    data () {
      return {}
    },
    props: {
      sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
      targetRows: { type: Number, default: 16 },
      targetColumns: { type: Number, default: 24 },
      sourcePlateNumber: { type: Number, default: 4 }
    },
    methods: {},
    components: {
      'lb-plate': Plate
    }
  }
</script>
