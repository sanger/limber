
<script>
  export default {
    name: 'TagGroupsLookup',
    data() {
      return {
        tagGroupsList: null,
        state: 'empty',
        invalidFeedback: '',
        validFeedback: ''
      }
    },
    props: {
      api: { required: false },
    },
    created: function () {
      this.lookupTagGroups()
    },
    methods: {
      lookupTagGroups: function (_) {
        this.findTagGroups()
            .then(this.validateTagGroups)
            .catch(this.apiError)
      },
      async findTagGroups () {
        this.state = 'searching'
        const tagGroupsList = (
          await this.api.findAll('tag_groups',{
          })
        )
        return tagGroupsList.data
      },
      validateTagGroups: function (tagGroupsList) {
        this.tagGroupsList = []
        if (tagGroupsList === undefined) {
          this.badState({ message: 'Tag groups list was undefined' })
        } else {
          if(tagGroupsList.length > 0) {
            for (var i = 0; i < tagGroupsList.length; i++) {
              this.extractTagGroupInfo(tagGroupsList[i])
            }
            this.goodState({ message: 'Valid!'})
          } else {
            this.badState({ message: 'No tag groups found' })
          }
        }
      },
      extractTagGroupInfo: function (tg) {
        let modifiedTg = { 'id': tg.id, 'name': tg.name, 'tags': tg.tags }
        this.tagGroupsList.push(modifiedTg)
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
        this.$emit('change', { tagGroupsList: this.tagGroupsList, state: this.state })
      }
    },
    // TODO can this be removed?
    render() {
    }
  }
</script>

