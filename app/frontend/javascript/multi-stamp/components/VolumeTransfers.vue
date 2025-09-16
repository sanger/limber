<template>
  <b-container fluid>
    <b-row>
      <b-col />
      <b-col>
        <b-input-group prepend="Volume" append="µL">
          <b-form-input id="input-volume" v-model="volume" type="number" :number="true" />
        </b-input-group>
      </b-col>
    </b-row>
  </b-container>
</template>

<script>
// Transfers creator that return an extra parameter containing the volume to be
// applied as an extra parameter to each transfer request
export default {
  name: 'VolumeTransfers',
  props: {
    defaultVolume: {
      default: null,
      type: Number,
    },
  },
  emits: ['update:model-value'],
  data() {
    return {
      volume: null,
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
    },
  },
  watch: {
    volume: function () {
      this.$emit('update:model-value', {
        extraParams: this.transferFunc,
        isValid: this.isValid,
      })
    },
  },
  created() {
    this.volume = this.defaultVolume
  },
}
</script>
