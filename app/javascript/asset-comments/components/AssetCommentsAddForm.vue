<template>
  <div>
    <div class="form-group form-row">
      <b-form-textarea name="asset_comment_textarea" id="asset_comment_textarea" v-model="assetComment" v-on:keypress="checkState()" placeholder="enter a new comment here..." :rows="2" :max-rows="5" maxlength="65535" tabindex="1"></b-form-textarea>
    </div>
    <b-button name="asset_comment_submit_button" id="asset_comment_submit_button" :disabled="disabled" :variant="buttonStyle" size="lg" block @click="submit">{{ buttonText }}</b-button>
  </div>
</template>

<script>
  import ApiModule from 'shared/api'

  export default {
    name: 'AssetCommentAddForm',
    data: function () {
      return {
        assetComment: '',
        state: 'pending'
      }
    },
    props: {
      commentTitle: { type: String, required: true }
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
      }
    },
    methods: {
      async submit() {
        if(this.isCommentInvalid()) { return }
        this.state = 'busy'
        var successful = await this.$root.$data.addComment(this.commentTitle, this.assetComment)
        if(successful) {
          this.state = 'success'
          this.assetComment = ''
        } else {
          this.state = 'failure'
        }
      },
      isCommentInvalid() {
        if(this.assetComment === undefined || this.assetComment === '') {
          return true
        }
        return false
      },
      checkState() {
        if(this.state == 'success' && this.isCommentInvalid()) {
          this.state = 'pending'
        }
      }
    }
  }
</script>
