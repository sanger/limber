<template>
  <lb-page>
    <lb-loading-modal
      v-if="loading"
      :message="progressMessage"
    />
    <lb-main-content>
      <h1>Main Content</h1>
    </lb-main-content>
    <lb-sidebar>
      <h1>Sidebar</h1>
    </lb-sidebar>
  </lb-page>
</template>

<script>
import LoadingModal from 'shared/components/LoadingModal'

export default {
  name: 'TubesToRack',
  components: {
    'lb-loading-modal': LoadingModal
  },
  props: {},
  data () {
    return {
      // Flag for toggling loading screen
      loading: false,

      // Message to be shown during loading screen
      progressMessage: ''
    }
  },
  computed: {},
  methods: {}
}
</script>
