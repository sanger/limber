<!-- Encapsulates the main page content
     Can have two children:
      - MainContent: The LHS, what you HAVE
      - Sidebar: The RHS, what you can do
-->
<template>
  <div class="container-fluid">
    <div class="js-alerts">
      <lb-alert
        v-for="alert in alerts"
        :key="alert.uid"
        :level="alert.level"
        :title="alert.title"
        :message="alert.message"
      ></lb-alert>
    </div>
    <div class="row">
      <slot />
    </div>
  </div>
</template>

<script>
import eventBus from 'shared/eventBus'
import Alert from 'shared/components/Alert'

export default {
  name: 'Page',
  components: {
    'lb-alert': Alert,
  },
  data() {
    return {
      alerts: [
        { level: 'info', title: 'Hello', message: 'This is an info message' },
        { level: 'success', title: 'Hello', message: 'This is a success message' },
        { level: 'warning', title: 'Hello', message: 'This is a warning message' },
        { level: 'danger', title: 'Hello', message: 'This is a danger message' },
      ],
    }
  },
  mounted() {
    eventBus.$on('push-alert', (data) => {
      // data = { level: [str], title: [str], message: [str] }
      this.addAlert(data)
    })
  },
  beforeDestroy() {
    // removing eventBus listener
    eventBus.$off('push-alert')
  },
  methods: {
    addAlert(data) {
      data.uid = Date.now()
      this.alerts.push(data)
    },
  },
}
</script>
