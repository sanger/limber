<script>
import DevourSelect from 'shared/components/mixins/devourSelect'
import { hasExpectedProperties } from 'shared/devourApiValidators'

export default {
  name: 'AssetLookupByUuid',
  mixins: [DevourSelect],
  props: {
    validation: {
      // A validation function. see plateScanValidators.js for examples and details
      // This overrides the property by the same name in the DevourSelect mixin.
      type: Function,
      required: false,
      default: hasExpectedProperties(['id', 'uuid', 'number_of_rows', 'number_of_columns']),
    },
  },
  data() {
    return {}
  },
  computed: {
    // This overrides the computed by the same name from the DevourSelect mixin.
    reformattedResults() {
      if (this.results && this.results[0]) {
        return this.results[0]
      }
      return null
    },
  },
  created() {
    this.performLookup()
  },
}
</script>
