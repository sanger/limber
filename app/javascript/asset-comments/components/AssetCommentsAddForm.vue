<template>
  <div>
    <div class="form-group form-row">
      <b-form-textarea
        id="asset_comment_textarea"
        v-model="assetComment"
        name="asset_comment_textarea"
        placeholder="enter a new comment here..."
        :rows="2"
        :max-rows="5"
        maxlength="65535"
        tabindex="1"
      />
    </div>
    <b-button
      id="asset_comment_submit_button"
      name="asset_comment_submit_button"
      :disabled="disabled"
      :variant="buttonStyle"
      size="lg"
      block
      @click="submit"
    >
      {{ buttonText }}
    </b-button>
  </div>
</template>

<script>
export default {
  name: 'AssetCommentAddForm',
  props: {
    commentTitle: { type: String, required: true }
  },
  data: function () {
    return {
      assetComment: '',
      state: 'pending',
      previous_success: null
    }
  },
  computed: {
    buttonText() {
      return {
        'pending': 'Add Comment to Sequencescape',
        'busy': 'Sending...',
        'success': 'Comment successfully added',
        'failure': 'Failed to add comment, retry?'
      }[this.state]
    },
    buttonStyle() {
      return {
        'pending': 'primary',
        'busy': 'outline-primary',
        'success': 'success',
        'failure': 'danger'
      }[this.state]
    },
    disabled() {
      return {
        'pending': this.isCommentInvalid(),
        'busy': true,
        'success': true,
        'failure': false
      }[this.state]
    },
    assetCommentTrimed() {
      return this.assetComment.trim()
    }
  },
  methods: {
    async submit() {
      if(this.isCommentInvalid()) { return }
      this.state = 'busy'
      var successful = await this.$root.$data.addComment(this.commentTitle, this.assetCommentTrimed)
      if(successful) {
        this.state = 'success'
        this.assetComment = ''
        this.previous_success = true
      } else {
        this.state = 'failure'
        this.previous_success = false
      }
    },
    isCommentInvalid() {
      if(this.assetCommentTrimed === undefined || this.assetCommentTrimed === '') {
        return true
      }
      if(this.previous_success != null && this.previous_success) {
        this.state = 'pending'
      }
      return false
    }
  }
}
</script>
