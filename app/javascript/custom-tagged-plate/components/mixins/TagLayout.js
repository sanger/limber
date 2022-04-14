import TagGroupsLookup from 'shared/components/TagGroupsLookup.vue'
import TagOffset from 'custom-tagged-plate/components/TagOffset.vue'

export default {
  name: 'TagLayout',
  components: {
    'lb-tag-groups-lookup': TagGroupsLookup,
    'lb-tag-offset': TagOffset,
  },
  props: {
    // A devour API object. eg. new devourClient(apiOptions)
    // Passed through to the tag groups lookup and tag plate scan child
    // components.
    api: {
      type: Object,
      required: true,
    },
    // The current number of useable tags, calculated by the parent component
    // and used to determine tag offset limits.
    numberOfTags: {
      type: Number,
      default: 0,
    },
    // The number of target wells, calculated by the parent component and
    // used to determine the tag offset limits.
    numberOfTargetWells: {
      type: Number,
      default: 0,
    },
    // The tags per well number, determined by the plate purpose and used here
    // to determine what tag layout walking by options are available.
    tagsPerWell: {
      type: Number,
      default: 1,
    },
  },
  data() {
    return {
      tagPlate: null, // holds the tag plate once scanned
      tagGroupsList: {}, // holds the list of tag groups once retrieved
      tag1GroupId: null, // holds the id of tag group 1 once selected
      tag2GroupId: null, // holds the id of tag group 2 once selected
      walkingBy: 'default', // (overriden) holds the chosen tag layout walking by option
      direction: 'column', // holds the chosen tag layout direction option
      offsetTagsBy: 0, // holds the entered tag offset number
      nullTagGroup: {
        // null tag group object used in place of a selected tag group
        uuid: null, // uuid of the tag group
        name: 'No tag group selected', // name of the tag group
        tags: [], // array of tags in the tag group
      },
      directionOptions: [
        { value: null, text: 'Please select a Direction Option...' },
        { value: 'row', text: 'By Rows' },
        { value: 'column', text: 'By Columns' },
        { value: 'inverse row', text: 'By Inverse Rows' },
        { value: 'inverse column', text: 'By Inverse Columns' },
      ],
    }
  },
  computed: {
    tag1Group() {
      return this.tagGroupsList[this.tag1GroupId] || this.nullTagGroup
    },
    tag2Group() {
      return this.tagGroupsList[this.tag2GroupId] || this.nullTagGroup
    },
    coreTagGroupOptions() {
      return Object.values(this.tagGroupsList).map((tagGroup) => {
        return { value: tagGroup.id, text: tagGroup.name }
      })
    },
    tag1GroupOptions() {
      return [{ value: null, text: 'Please select an i7 Tag 1 group...' }].concat(this.coreTagGroupOptions.slice())
    },
    tag2GroupOptions() {
      return [{ value: null, text: 'Please select an i5 Tag 2 group...' }].concat(this.coreTagGroupOptions.slice())
    },
  },
  methods: {
    tagOffsetChanged(tagOffset) {
      this.offsetTagsBy = tagOffset
      this.updateTagParams()
    },
    tagGroupsLookupUpdated(data) {
      this.tagGroupsList = {}
      if (data.state === 'valid' && data.results) {
        this.tagGroupsList = data.results
      }
    },
    updateTagParams() {
      const updatedData = {
        tagPlate: this.tagPlate,
        tag1Group: this.tag1Group,
        tag2Group: this.tag2Group,
        walkingBy: this.walkingBy,
        direction: this.direction,
        offsetTagsBy: this.offsetTagsBy,
      }

      this.$emit('tagparamsupdated', updatedData)
    },
  },
}
