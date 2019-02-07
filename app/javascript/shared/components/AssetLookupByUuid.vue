
<script>
  export default {
    name: 'AssetLookupByUuid',
    data() {
      return {
        asset: null,
        state: 'empty',
        invalidFeedback: '',
        validFeedback: ''
      }
    },
    props: {
      api: { required: false },
      assetUuid: { type: String, required: true },
      assetType: { type: String, default:() => { return 'plate' }},
      includes: { type: String, default: () => { return '' } },
      fields: { type: Object, default: () => { return {} } }
    },
    created: function () {
      this.lookupAsset()
    },
    methods: {
      lookupAsset: function (_) {
        if (this.assetUuid !== '') {
          this.findAsset()
              .then(this.validateAsset)
              .catch(this.apiError)
        } else {
          this.asset = null
          this.state = 'empty'
          this.invalidFeedback = 'Asset uuid blank'
        }
      },
      async findAsset () {
        this.state = 'searching'
        console.log('findAsset: this.assetUuid = ' + this.assetUuid)
        console.log('findAsset: this.assetType = ' + this.assetType)
        console.log('findAsset: this.includes = ' + this.includes)
        console.log('findAsset: this.fields = ' + JSON.stringify(this.fields))
        const asset = (
          await this.api.findAll(this.assetType,{
            include: this.includes,
            filter: { uuid: this.assetUuid },
            fields: this.fields
          })
        )
        console.log('findAsset: asset = ' + JSON.stringify(asset))
        console.log('findAsset: asset.data[0] = ' + JSON.stringify(asset.data[0]))
        return asset.data[0]
      },
      validateAsset: function (asset) {
        if (asset === undefined) {
          this.asset = null
          this.badState({ message: 'Asset undefined' })
        } else {
          this.asset = asset
          this.goodState({ message: 'Valid!'})
        }
      },
      apiError: function (err) {
        if (!err) {
          this.badState({ message: 'Unknown Api error' })
        } else if (err[0]) {
          const message = `${err[0].title}: ${err[0].detail}`
          this.badState({ message })
        } else {
          this.badState(err)
        }
      },
      badState: function (err) {
        this.state = 'invalid'
        this.invalidFeedback = err.message || 'Unknown error'
      },
      goodState: function (msg) {
        this.state = 'valid'
        this.validFeedback = msg || 'Valid!'
      }
    },
    watch: {
      state: function() {
        this.$emit('change', { asset: this.asset, state: this.state })
      }
    },
    render() {
    }
  }
</script>

