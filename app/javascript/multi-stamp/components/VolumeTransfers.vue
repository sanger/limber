<template>
  <b-container fluid>
    <b-row>
      <b-col>
        <label for="input-volume">Volume (&#181;L):</label>
      </b-col>
      <b-col>
        <b-input
          id="input-volume"
          v-model="volume"
          type="number"
          number="true"
        />
      </b-col>
    </b-row>
  </b-container>
</template>

<script>

// Transfers creator that return an extra parameter containing the volume to be
// applied as an extra parameter to each transfer request
export default {
  name: 'VolumeTransfers',
  data () {
    return {
      volume: null
    }
  },
  computed: {
    transferFunc() {
      return (_transfer) => {
        return { volume: this.volume }
      }
    },
    isValid() {
      return !isNaN(Number.parseFloat(this.volume))
    }
  },
  watch: {
    volume: function () {
      this.$emit('change', {
        extraParams: this.transferFunc,
        isValid: this.isValid
      })
    }
  }
}
</script>
