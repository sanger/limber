<template>
  <lb-page>
    <lb-loading-modal
      v-if="loading"
      :message="progressMessage"
    />
    <lb-main-content>
      <b-h1>Hello</b-h1>
    </lb-main-content>
    <lb-sidebar>
    </lb-sidebar>
  </lb-page>
</template>

<script>
export default {
  name: 'TubesToRack'
}
</script>
