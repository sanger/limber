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
        @close="removeAlert(alert.uid)"
      ></lb-alert>
    </div>
    <div class="row">
      <slot />
    </div>
  </div>
</template>

<script>
import LbAlert from '@/javascript/shared/components/Alert.vue'
import eventBus from '@/javascript/shared/eventBus.js'
import uniqueSlug from 'unique-slug'

export default {
  name: 'LbPage',
  components: {
    'lb-alert': LbAlert,
  },
  data() {
    return {
      alerts: [],
    }
  },
  mounted() {
    eventBus.$on('push-alert', (data) => {
      // data = { level: [str], title: [str], message: [str] }
      this.addAlert(data)
    })
  },
  beforeUnmount() {
    // removing eventBus listener
    eventBus.$off('push-alert')
  },
  methods: {
    addAlert(data) {
      data.uid = uniqueSlug()
      this.alerts.push(data)
    },
    removeAlert(uid) {
      this.alerts = this.alerts.filter((alert) => alert.uid !== uid)
    },
  },
}
</script>
