<!-- Encapsulates the main page content
     Can have two children:
      - MainContent: The LHS, what you HAVE
      - Sidebar: The RHS, what you can do
-->
<template>
  <div class="content-main">
    <slot></slot>
  </div>
</template>

<script>
  export default {
    name: 'MainContent'
  }
</script>
