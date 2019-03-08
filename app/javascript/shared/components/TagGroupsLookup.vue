
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
        this.state = 'searching'
        this.findAllTagGroups()
            .then(this.validateTagGroups)
            .catch(this.apiError)
      },
      // TODO abstract out this method to helper function with name and size as parameters
      async findAllTagGroups () {
        let tagGroupsFromDB = []
        let morePagesAvailable = true
        let currentPage = 0

        while(morePagesAvailable) {
          currentPage++
          const response = await this.api.findAll('tag_groups', {page: {number: currentPage, size: 150}})
          const numTagGroups = response.data.length

          if(response.data.length > 0) {
            response.data.forEach(e => tagGroupsFromDB.unshift(e))
          }
          // use existence of next link to decide if more pages available
          morePagesAvailable = (response.links.next)
        }

        return tagGroupsFromDB
      },
      validateTagGroups: function (tagGroupsFromDB) {
        this.tagGroupsList = null
        if (!tagGroupsFromDB) {
          this.badState({ message: 'No tag groups list returned from database' })
        } else {
          if(tagGroupsFromDB.length > 0) {
            this.tagGroupsList = {}
            for (var i = 0; i < tagGroupsFromDB.length; i++) {
              this.extractTagGroupInfo(tagGroupsFromDB[i])
            }
            this.goodState({ message: 'Valid!'})
          } else {
            this.badState({ message: 'No tag groups found' })
          }
        }
      },
      extractTagGroupInfo: function (tagGroup) {
        // sort tags ascending by index (map id)
        let orderedTags = tagGroup.tags.sort(function(obj1, obj2) { return obj1.index - obj2.index })
        this.tagGroupsList[tagGroup.id] = { 'id': tagGroup.id, 'uuid': tagGroup.uuid, 'name': tagGroup.name, 'tags': orderedTags }
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

