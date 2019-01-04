<template>
  <span :class="['badge', 'badge-pill', badgeClass]">{{ commentCount }}</span>
</template>

<script>

const dateOptions = { year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute:'2-digit' };

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
