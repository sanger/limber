<!-- Encapsulates the main page content
     Can have two children:
      - MainContent: The LHS, what you HAVE
      - Sidebar: The RHS, what you can do
-->
<template>
  <div class="content-secondary sidebar">
    <slot />
  </div>
</template>

<script>
export default {
  name: 'Sidebar',
}
</script>
