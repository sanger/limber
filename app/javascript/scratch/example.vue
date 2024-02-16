<template>
  <div>
    <h1>{{ message }}</h1>
  </div>
</template>

<script>
export default {
  data() {
    return {
      message: 'Hello, World!',
    }
  },
  computed: {
    hello() {
      return 'Hello'
    },
  },
  methods: {
    world() {
      return 'World!'
    },
  },
}
</script>

<style scoped>
h1 {
  color: blue;
}
</style>
