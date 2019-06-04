<template>
  <span :class="['badge', 'badge-pill', badgeClass]">{{ commentCount }}</span>
</template>

<script>

export default {
  name: 'AssetComments',
  computed: {
    commentCount() {
      if (this.comments) {
        return this.comments.length
      } else {
        return '...'
      }
    },
    badgeClass() {
      if (this.comments && this.comments.length > 0) {
        return 'badge-success'
      } else {
        return 'badge-secondary'
      }
    },
    comments() { return this.$root.$data.comments }
  }
}
</script>
