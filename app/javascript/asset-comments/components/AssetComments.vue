<template>
  <ul class="comments-list list-group list-group-flush">
    <li v-for="comment in sortedComments" class="list-group-item">
      <div class="mb-1"><strong>{{ comment.title }}</strong></div>
      <div class="mb-1" style="white-space: pre">{{ comment.description }}</div>
      <div class="d-flex w-100 justify-content-between text-muted ">
        <small class="user-name">{{ comment.user.firstName }} {{ comment.user.lastName }} ({{ comment.user.login }})</small>
        <small class="comment-date">{{ comment.createdAt | formatDate }}</small>
      </div>
    </li>
    <li v-if="noComments" class="no-comment">No comments available</li>
    <li v-if="inProgress" class="spinner-dark">Loading</li>
  </ul>
</template>

<script>

const dateOptions = { year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute:'2-digit' };
const formatDate = function(date) {
  const dateObject = new Date(date)
  return dateObject.toLocaleString('en-GB', dateOptions)
}

export default {
  name: 'AssetComments',
  computed: {
    noComments() { return this.comments && this.comments.length === 0 },
    inProgress() { return !this.comments },
    comments() { return this.$root.$data.comments },
    sortedComments() {
      if(this.comments) {
        return this.comments.sort((a, b) => {
          return new Date(b.createdAt) - new Date(a.createdAt)
        })
      }
    },
  },
  filters: {
    formatDate: formatDate
  }
}
</script>
