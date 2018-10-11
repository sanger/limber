<!-- Encapsulates the main page content
     Can have two children:
      - MainContent: The LHS, what you HAVE
      - Sidebar: The RHS, what you can do
-->
<template>

</template>

<script>
  export default {
    name: 'PlateScan',
    props: {
      sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
    },
    computed: {
    },
    filters: {
    }
  }
</script>
