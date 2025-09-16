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
    <div class="d-grid">
      <b-button
        id="asset_comment_submit_button"
        name="asset_comment_submit_button"
        class="w-100"
        :disabled="disabled"
        :variant="buttonStyle"
        size="lg"
        @click="submit"
      >
        {{ buttonText }}
      </b-button>
    </div>
  </div>
</template>

<script>
import { createCommentFactory, removeCommentFactory } from '@/javascript/asset-comments/comment-store-helpers.js'

export default {
  name: 'AssetCommentAddForm',
  props: {
    commentTitle: { type: String, required: true },
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
      assetComment: '',
      state: 'pending',
      previous_success: null,
      commentFactory: null,
    }
  },
  computed: {
    buttonText() {
      return {
        pending: 'Add Comment to Sequencescape',
        busy: 'Sending...',
        success: 'Comment successfully added',
        failure: 'Failed to add comment, retry?',
      }[this.state]
    },
    buttonStyle() {
      return {
        pending: 'primary',
        busy: 'outline-primary',
        success: 'success',
        failure: 'danger',
      }[this.state]
    },
    disabled() {
      return {
        pending: this.isCommentInvalid(),
        busy: true,
        success: true,
        failure: false,
      }[this.state]
    },
    assetCommentTrimmed() {
      return this.assetComment.trim()
    },
  },
  mounted() {
    const commentFactory = createCommentFactory({
      sequencescapeApi: this.sequencescapeApi,
      assetId: this.assetId,
      sequencescapeApiKey: this.sequencescapeApiKey,
      userId: this.userId,
    })
    this.commentFactory = commentFactory
  },
  beforeUnmount() {
    removeCommentFactory(this.assetId)
  },
  methods: {
    async submit() {
      if (this.isCommentInvalid()) {
        return
      }
      this.state = 'busy'
      const successful = await this.commentFactory?.addComment(this.commentTitle, this.assetCommentTrimmed)
      if (successful) {
        this.state = 'success'
        this.assetComment = ''
        this.previous_success = true
      } else {
        this.state = 'failure'
        this.previous_success = false
      }
    },
    isCommentInvalid() {
      if (this.assetCommentTrimmed === undefined || this.assetCommentTrimmed === '') {
        return true
      }
      if (this.previous_success != null && this.previous_success) {
        this.state = 'pending'
      }
      return false
    },
  },
}
</script>
