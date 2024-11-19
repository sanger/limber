<template>
  <span :class="['badge', 'badge-pill', badgeClass]">{{ commentCount }}</span>
</template>

<script>

import eventBus from '@/javascript/shared/eventBus.js'

export default {
  name: 'AssetComments',
  data: function () {
    return {
      comments: null,
    }
  },
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
    // comments() {
    //   return this.$root.$data.comments
    // },
  },
  created() {
    // Listen for the event
    eventBus.$on('update-comment', (commentFactory) => {
      this.comments = commentFactory.comments;
    });
  },
  beforeDestroy() {
    // Clean up the event listener
    eventBus.$off('update-comment');
  },
}
</script>
