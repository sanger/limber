<template>
  <span :class="['badge', 'rounded-pill', badgeClass]">{{ commentCount }}</span>
</template>

<script>
import eventBus from '@/javascript/shared/eventBus.js'
import { createCommentFactory, removeCommentFactory } from '@/javascript/asset-comments/comment-store-helpers.js'

export default {
  name: 'AssetComments',
  props: {
    sequencescapeApi: {
      type: String,
      required: true,
    },
    assetId: {
      type: String,
      required: true,
    },
    sequencescapeApiKey: {
      type: String,
      required: true,
    },
    userId: {
      type: String,
      required: true,
    },
  },
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
      if (this.comments?.length > 0) {
        return 'bg-success'
      } else {
        return 'bg-secondary'
      }
    },
  },
  async mounted() {
    this.commentFactory = createCommentFactory({
      sequencescapeApi: this.sequencescapeApi,
      assetId: this.assetId,
      sequencescapeApiKey: this.sequencescapeApiKey,
      userId: this.userId,
    })
    await this.commentFactory.refreshComments()
    this.comments = this.commentFactory.comments
  },
  beforeUnmount() {
    removeCommentFactory(this.assetId)
    eventBus.$off('update-comments')
  },
  created() {
    // Listen for the event
    eventBus.$on('update-comments', (data) => {
      if (data.assetId !== this.assetId) {
        return
      }
      this.comments = data.comments
    })
  },
}
</script>
