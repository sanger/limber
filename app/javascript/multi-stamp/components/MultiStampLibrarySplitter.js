import MultiStamp from './MultiStamp'
import Vue from 'vue'
import { 
  checkSize, checkDuplicates, checkMaxCountRequests, 
  checkLibraryTypesInAllWells,
  checkAllRequestsWithSameReadySubmissions,
  checkPlateWithSameReadySubmissions,
  checkMinCountRequests, checkAllSamplesInColumnsList/* checkExcess */ 
} from 'shared/components/plateScanValidators'
import { baseTransferCreator } from 'shared/transfersCreators'
import MemoryOutputFileSystem from 'webpack/lib/MemoryOutputFileSystem'

export default Vue.extend({
  mixins: [MultiStamp],
  props: {
    childrenLibraryTypeToPurposeMappingJson: { type: String, required: true },
  },
  computed: {
    childrenLibraryTypeToPurposeMapping() {
      return JSON.parse(this.childrenLibraryTypeToPurposeMappingJson)
    },
    libraryTypes() {
      return Object.keys(this.childrenLibraryTypeToPurposeMapping)
    },
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
        checkMaxCountRequests(24),
        checkMinCountRequests(1),
        checkAllSamplesInColumnsList(['1', '2', '3']),
        checkLibraryTypesInAllWells(this.libraryTypes),
        checkAllRequestsWithSameReadySubmissions(),
        checkPlateWithSameReadySubmissions({})
        // checkExcess(this.excessTransfers)
      ]
    },
    validateLibraryTypeForEveryRequest() {
      return this.validTransfers.every((transfer) => (this.libraryTypes.indexOf(transfer.request.libraryType)>=0))
    },
    transfersError() {
      const errorMessages = []
      if (this.duplicatedTransfers.length > 0) {
        var sourceBarcodes = new Set()
        this.duplicatedTransfers.forEach(transfer => {
          sourceBarcodes.add(transfer.plateObj.plate.labware_barcode.human_barcode)
        })

        const msg = 'This would result in multiple transfers into the same well. Check if the source plates ('
                    + [...sourceBarcodes].join(', ')
                    + ') have more than one active submission.'
        errorMessages.push(msg)
      }
      if (this.excessTransfers.length > 0) {
        errorMessages.push('excess transfers')
      }
      //debugger;
      return errorMessages.join(' and ')
    }
  },
  methods: {
    updatePlate(index, data) {
      this.$set(this.plates, index - 1, {...data, index: index - 1 })
    },
    apiTransfers() {
      return this.validTransfersByTargetPlate.reduce((memo, transfers) => {
        const library_type = transfers[0].request.library_type
        memo[library_type] = baseTransferCreator(transfers, this.transfersCreatorObj.extraParams)
        return memo
      }, {})
    },
    createPlate() {
      this.progressMessage = 'Creating plates...'
      this.loading = true
      let apiTransfers = this.apiTransfers()
      let payloads = Object.keys(apiTransfers).map((libraryType) => {
        const transfers = apiTransfers[libraryType]
        return {
          plate: {
            parent_uuid: this.validPlates[0].plate.uuid,
            purpose_uuid: this.childrenLibraryTypeToPurposeMapping[libraryType],
            transfers: transfers
          }
        }
      })

      return Promise.all(payloads.map((payload) => {
        return this.$axios({
          method: 'post',
          url: this.targetUrl,
          headers: {'X-Requested-With': 'XMLHttpRequest'},
          data: payload
        })
      })).then((responses) => {
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
