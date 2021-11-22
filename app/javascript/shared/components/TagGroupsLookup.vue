
<script>
import DevourSelect from 'shared/components/mixins/devourSelect'
import { hasExpectedProperties } from 'shared/devourApiValidators'

export default {
  name: 'TagGroupsLookup',
  mixins: [DevourSelect],
  props: {
    validation: {
      // A validation function. see plateScanValidators.js for examples and details
      // This overrides the property by the same name in the DevourSelect mixin.
      type: Function,
      required: false,
      default: hasExpectedProperties(['id', 'uuid', 'name', 'tags'])
    }
  },
  data() {
    return {
    }
  },
  computed: {
    // This overrides the computed by the same name from the DevourSelect mixin.
    reformattedResults() {
      let tagGroupsList = {}
      const resultsLength = this.results.length
      if(resultsLength > 0) {
        this.results.forEach(function (currTagGroup) {
          const orderedTags = currTagGroup.tags.sort(function(obj1, obj2) { return obj1.index - obj2.index })
          tagGroupsList[currTagGroup.id] = {
            'id': currTagGroup.id,
            'uuid': currTagGroup.uuid,
            'name': currTagGroup.name,
            'tags': orderedTags
          }
        })
      }
      return tagGroupsList
    }
  },
  created() {
    this.performLookup()
  },
  methods: {
    // This overrides the method by the same name from the DevourSelect mixin.
    async performFind() {
      let tagGroupsArray = []
      let morePagesAvailable = true
      let currentPage = 0

      while(morePagesAvailable) {
        currentPage++
        const response = await this.api.findAll(this.resourceName, {
          filter: this.filter,
          page: { number: currentPage, size: 150 }
        })
        if(response.data.length > 0) {
          response.data.forEach(e => tagGroupsArray.unshift(e))
        }
        // uses existence of next link to decide if more pages are available
        morePagesAvailable = (response.links.next)
      }

      return tagGroupsArray
    }
  }
}
</script>

