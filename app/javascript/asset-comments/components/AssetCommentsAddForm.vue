<template>
  <div>
    <div class="form-group form-row">
      <input class="form-control" type="text" id="asset_comment" name="asset_comment" v-model.trim="assetComment" placeholder="e.g. any special instructions or information" tabindex="1"/>
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
        isSubmitted: false,
      }
    },
    computed: {
      isDisabled() {
        return this.isSubmitted || this.assetComment == ''
      }
    },
    methods: {
      submit() {
        this.isSubmitted=true // disable submit button
        this.$root.$data.addComment(this.assetComment) // add comment to this asset
      }
    }
  }
</script>
