<template>
  <ul class="comments-list list-group list-group-flush">
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
        <small class="comment-date">{{ comment.created_at | formatDate }}</small>
      </div>
    </li>
    <li v-if="noComments" class="no-comment">No comments available</li>
    <li v-if="inProgress" class="spinner-dark">Loading</li>
  </ul>
</template>

<script>
export default {
  name: 'AssetComments',
  filters: {
    formatDate(value) {
      // return date like 30 September 2017, 12:18
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ]
      const date = new Date(value)
      const day = date.getDate()
      const month = months[date.getMonth()]
      const year = date.getFullYear()
      const hour = date.getHours().toString().padStart(2, '0')
      const minute = date.getMinutes().toString().padStart(2, '0')
      return `${day} ${month} ${year}, ${hour}:${minute}`
    },
  },
  computed: {
    noComments() {
      return this.comments && this.comments.length === 0
    },
    inProgress() {
      return !this.comments
    },
    comments() {
      return this.$root.$data.comments
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
}
</script>
