<template>
  <div>
    <div class="form-group form-row">
    	<input class="form-control" type="text" id="asset_comment" name="asset_comment" placeholder="e.g. any special instructions or information" tabindex="1"/>
    </div>
    <button class="btn btn-success btn-lg btn-block">Add comment</button>
  </div>
</template>

<script>
  import ApiModule from 'shared/api'

  export default {
    name: 'AssetCommentAddForm',
    data () {
      return {
      	assetComment: '',
      }
    },
    props: {
    },
    computed: {
    },
    methods: {
      submit() {
        return {
        }
      }
    },
    components: {
    }
  }
</script>
