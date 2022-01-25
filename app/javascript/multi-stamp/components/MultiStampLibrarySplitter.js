import MultiStamp from './MultiStamp'
import Vue from 'vue'
import { 
  checkSize, checkDuplicates, checkMaxCountRequests, 
  checkMinCountRequests, checkAllSamplesInColumnsList/* checkExcess */ 
} from 'shared/components/plateScanValidators'
import { baseTransferCreator } from 'shared/transfersCreators'

export default Vue.extend({
  mixins: [MultiStamp],
  computed: {
    validTransfersByTargetPlate() {
      return this.validTransfers.reduce((memo, transfer) => { 
        if (typeof memo[transfer.targetPlate] === 'undefined') {
          memo[transfer.targetPlate] = []
        }
        memo[transfer.targetPlate].push(transfer)
        return memo
      }, [])
    },
    excessTransfers() {
      return this.validTransfersByTargetPlate.map((transfers) => {
        return transfers.slice(this.targetRowsNumber * this.targetColumnsNumber)
      }).flat()
    },
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
  },
  methods: {
    updatePlate(index, data) {
      this.$set(this.plates, index - 1, {...data, index: index - 1 })
    },
    apiTransfers() {
      return baseTransferCreator(this.validTransfers, this.transfersCreatorObj.extraParams)
    },
    createPlate() {
      debugger
      this.progressMessage = 'Creating plates...'
      this.loading = true
      let payloads = this.apiTransfers().map((transfers) => {
        return {
          plate: {
            parent_uuid: this.validPlates[0].plate.uuid,
            purpose_uuid: this.purposeUuid,
            transfers: transfers
          }
        }
      })

      return payloads.map((payload) => {
        return this.$axios({
          method: 'post',
          url: this.targetUrl,
          headers: {'X-Requested-With': 'XMLHttpRequest'},
          data: payload
        })
      }).then((responses) => {
        const response = responses[0]
        // Ajax responses automatically follow redirects, which
        // would result in us receiving the full HTML for the child
        // plate here, which we'd then need to inject into the
        // page, and update the history. Instead we don't redirect
        // application/json requests, and redirect the user ourselves.
        this.progressMessage = response.data.message
        this.locationObj.href = response.data.redirect
      }).catch((error) => {
        // Something has gone wrong
        console.error(error)
        this.loading = false
      })
    }
  }


})
