<template>
  <ul class="comments-list list-group list-group-flush rounded-bottom">
    <li v-for="comment in sortedComments" :key="comment.id" class="list-group-item">
      <div class="mb-1">
        <strong>{{ comment.title }}</strong>
      </div>
      <div class="mb-1" style="white-space: pre">
        {{ comment.description }}
      </div>
      <div class="d-flex w-100 justify-content-between text-muted">
        <small class="user-name"
          >{{ comment.user.first_name }} {{ comment.user.last_name }} ({{ comment.user.login }})</small
        >
        <small class="comment-date">{{ formatDate(comment.created_at) }}</small>
      </div>
    </li>
    <li v-if="noComments" class="no-comment">No comments available</li>
    <li v-if="inProgress" class="spinner-dark">Loading</li>
  </ul>
</template>

<script>
import { createCommentFactory, removeCommentFactory } from '@/javascript/asset-comments/comment-store-helpers.js'
import eventBus from '@/javascript/shared/eventBus.js'

const dateOptions = {
  year: 'numeric',
  month: 'long',
  day: 'numeric',
  hour: 'numeric',
  minute: '2-digit',
}

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
    noComments() {
      return this.comments && this.comments.length === 0
    },
    inProgress() {
      return !this.comments
    },
    sortedComments() {
      if (this.comments) {
        // Sort mutates the array, so we do a shallow copy before sorting
        return [...this.comments].sort((a, b) => {
          return new Date(b.created_at) - new Date(a.created_at)
        })
      } else {
        return []
      }
    },
  },
  async mounted() {
    const commentFactory = createCommentFactory({
      sequencescapeApi: this.sequencescapeApi,
      assetId: this.assetId,
      sequencescapeApiKey: this.sequencescapeApiKey,
      userId: this.userId,
    })
    await commentFactory.refreshComments()
    this.comments = commentFactory.comments
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
  methods: {
    formatDate(date) {
      const dateObject = new Date(date)
      return dateObject.toLocaleString('en-GB', dateOptions)
    },
  },
}
</script>
