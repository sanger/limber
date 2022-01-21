import MultiStamp from './MultiStamp'
import Vue from 'vue'
import { 
  checkSize, checkDuplicates, checkMaxCountRequests, 
  checkMinCountRequests, checkAllSamplesInColumnsList/* checkExcess */ 
} from 'shared/components/plateScanValidators'


export default Vue.extend({
  mixins: [MultiStamp],
  computed: {
    scanValidation() {
      const currPlates = this.plates.map(plateItem => plateItem.plate)
      return [
        checkSize(12, 8),
        checkDuplicates(currPlates),
        checkMaxCountRequests(currPlates, 24),
        checkMinCountRequests(currPlates, 1),
        checkAllSamplesInColumnsList(currPlates, ["1", "2", "3"])
        // checkExcess(this.excessTransfers)
      ]
    },
    valid() {
      //debugger
      return true
    }
  }
})
