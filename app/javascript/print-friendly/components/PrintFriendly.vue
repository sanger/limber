<template>
  <div>
    <!-- SOURCE -->
    <div id="printMe">
      <h1>Print me!</h1>
      {{ test }}
    </div>
    <!-- OUTPUT -->
    <button @click="print" type="button" class="btn btn-info">Printer friendly version</button>
  </div>
</template>

<script>

export default {
  name: 'PrintFriendly',
  data () {
    return {
      output: null,
      test: JSON.parse(this.id)['pools_hash']
    }
  },
  props: {
    id:{
      type: String,
      required: true
    }
  },
  methods: {
    print () {
      // Pass the element id here
      this.$htmlToPaper('printMe');
    }
  }
}
</script>
