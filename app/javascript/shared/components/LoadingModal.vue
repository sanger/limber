<!-- The progress modal covers the screen with a spinner and provides feedback -->

<template>
  <div class="modal-container" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
      <div class="spinner text-white"></div>
      <span class="modal-message">{{ message }}</span>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'loadingModal',
    props: {
      message: { type: String, default: 'Please wait...' }
    }
  }
</script>


<style scoped>
  .modal-container {
    top: 0px;
    left: 0px;
    background-color: rgba(0, 0, 0, 0.5);
    width: 100%;
    height: 100%;
    position: fixed;
    z-index: 300;
  }
  .modal-message {
    color: white;
    display: block;
    text-align: center;
    font-size: xx-large;
  }
</style>
