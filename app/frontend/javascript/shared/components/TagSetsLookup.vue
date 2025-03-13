<script>
import DevourSelect from '@/javascript/shared/components/mixins/devourSelect.js'
import { hasExpectedProperties } from '@/javascript/shared/devourApiValidators.js'

export default {
  name: 'TagSetsLookup',
  mixins: [DevourSelect],
  props: {
    validation: {
      // A validation function. see plateScanValidators.js for examples and details
      // This overrides the property by the same name in the DevourSelect mixin.
      type: Function,
      required: false,
      default: hasExpectedProperties(['id', 'uuid', 'name']),
    },
  },
  data() {
    return {}
  },
  computed: {
    // This overrides the computed by the same name from the DevourSelect mixin.
    reformattedResults() {
      let tagSetsList = {}
      const resultsLength = this.results.length
      if (resultsLength > 0) {
        this.results.forEach(function (currTagSet) {
          const sortTags = (tags) => tags.sort((obj1, obj2) => obj1.index - obj2.index)
          tagSetsList[currTagSet.id] = {
            id: currTagSet.id,
            uuid: currTagSet.uuid,
            name: currTagSet.name,
            tag_group: { ...currTagSet.tag_group, tags: sortTags(currTagSet.tag_group.tags) },
            tag2_group: currTagSet.tag2_group?{ ...currTagSet.tag2_group, tags: sortTags(currTagSet.tag2_group.tags) }:null,
          }
        })
      }
      return tagSetsList
    },
  },
  created() {
    this.performLookup()
  },
  methods: {
    // This overrides the method by the same name from the DevourSelect mixin.
    async performFind() {
      let tagSetsArray = []
      let morePagesAvailable = true
      let currentPage = 0

      while (morePagesAvailable) {
        currentPage++
        const response = await this.api.findAll(this.resourceName, {
          filter: this.filter,
          include: this.includes,
          page: { number: currentPage, size: 150 },
        })
        if (response.data.length > 0) {
          response.data.forEach((e) => tagSetsArray.unshift(e))
        }
        // uses existence of next link to decide if more pages are available
        morePagesAvailable = response.links.next
      }

      return tagSetsArray
    },
  },
}
</script>
