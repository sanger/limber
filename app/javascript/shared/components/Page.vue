<!-- Encapsulates the main page content
     Can have two children:
      - MainContent: The LHS, what you HAVE
      - Sidebar: The RHS, what you can do
-->
<template>
  <div class="container-fluid">
    <div class="row">
      <slot />
    </div>
  </div>
</template>

<script>
export default {
  name: 'Page'
}
</script>
