<template>
  <div>
    <div class="form-group form-row">
      <textarea maxlength="65535" class="form-control" type="text" id="asset_comment" name="asset_comment" v-model.trim="assetComment" placeholder="e.g. any special instructions or information" tabindex="1"/>
    </div>
    <button class="btn btn-success btn-lg btn-block" v-on:click="submit" v-bind:disabled="isDisabled">Add comment</button>
  </div>
</template>

<script>
  import ApiModule from 'shared/api'

  export default {
    name: 'AssetCommentAddForm',
    data: function () {
      return {
        assetComment: '',
        inProgress: false,
      }
    },
    computed: {
      isDisabled() {
        return this.inProgress || this.assetComment === ''
      }
    },
    methods: {
      async submit() {
        this.inProgress=true
        await this.$root.$data.addComment(this.assetComment)
        // clear and enable the add comment form
        this.assetComment=undefined
        this.inProgress=false
      }
    }
  }
</script>
