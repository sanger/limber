<template>
  <div :class="{'bordered-badge p-1': displayStatus}">
    <b-button
      id="pool_xp_tube_submit_button"
      name="pool_xp_tube_submit_button"
      :disabled="busy"
      :variant="buttonStyle"
      :class="{'btn-gray': busy}"
      size="lg"
      block
      @click="submitTube"
    >
      Submit Tube to Traction
    </b-button>
    <b-badge v-if="displayStatus" size="lg" class="p-2 mt-2 d-block badge-light">
      <b-spinner small type="border" class="mr-2"/>
      {{ statusText }}
    </b-badge>
  </div>
</template>

<script>
export default {
  name: 'PoolXPTubeSubmitPanel',
  props: {
    barcode: {
      type: String,
      required: true,
    },
    userId: {
      type: String,
      required: true,
    },
    sequencescapeApiUrl: {
      type: String,
      required: true,
    },
    sequencescapeUrl: {
      type: String,
      required: true,
    },
  },
  data: function () {
    return {
      form: {},
      state: 'ready',
    }
  },
  computed: {
    statusText() {
      return {
        ready: '',
        submitting: 'Submitting...',
        waiting: 'Waiting for Traction to process...',
        success: 'Tube successfully added',
        failure: 'Failed to add tube, retry?',
      }[this.state]
    },
    buttonStyle() {
      return {
        ready: 'primary',
        submitting: 'outline-primary',
        waiting: 'outline-primary',
        success: 'success',
        failure: 'danger',
      }[this.state]
    },
    busy() {
      return this.state === 'submitting' || this.state === 'waiting'
    },
    displayStatus() {
      return this.state !== 'ready'
    },
    url() {
      return `${this.sequencescapeApiUrl}/bioscan/export_pool_xp_to_traction`
    },
    payload() {
      return {
        data: {
          attributes: {
            barcode: this.barcode,
          },
        },
      }
    },
  },
  mounted() {},
  methods: {
    async submitTube() {
      this.state = 'submitting'
      try {
        const response = await fetch(this.url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(this.payload),
        })
        if (response.ok) {
          this.state = 'waiting'
        } else {
          this.state = 'failure'
        }
      } catch (error) {
        this.state = 'failure'
      }
    },
  },
}
</script>

<style scoped>
.tooltip {
  font-size: 1rem;
}
.bordered-badge {
  background-color: #f8f9fa; /* Light background color */
  color: #343a40; /* Dark text color */
  border: 2px solid #d3d3d3; /* Light gray border color */
  border-radius: 0.25rem; /* Rounded corners */
}
.btn-gray {
  background-color: #d3d3d3 !important; /* Light gray background color */
  border-color: #6c757d !important; /* Dark gray border color */
  color: #6c757d !important; /* Dark gray text color */
}
</style>
