import {
  checkAllLibraryRequestsWithSameReadySubmissions,
  checkAllSamplesInColumnsList,
  checkDuplicates,
  checkLibraryTypesInAllWells,
  checkMaxCountRequests,
  checkMinCountRequests,
  checkPlateWithSameReadyLibrarySubmissions,
  checkSize,
} from '@/javascript/shared/components/plateScanValidators'
import { handleFailedRequest } from '@/javascript/shared/requestHelpers.js'
import { transferPlatesToPlatesCreator } from '@/javascript/shared/transfersCreators.js'
import MultiStamp from './MultiStamp.vue'

export default {
  mixins: [MultiStamp],
  props: {
    childrenLibraryTypeToPurposeMappingJson: {
      default: '{}',
      validator(value) {
        try {
          JSON.parse(value)
        } catch (e) {
          return false
        }
        return true
      },
    },
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
        memo[transfer.targetPlate] ??= []
        memo[transfer.targetPlate].push(transfer)
        return memo
      }, [])
    },
    excessTransfers() {
      return this.validTransfersByTargetPlate.flatMap((transfers) => {
        return transfers.slice(this.targetRowsNumber * this.targetColumnsNumber)
      })
    },
    scanValidation() {
      const currPlates = this.plates.map((plateItem) => plateItem.plate)
      return [
        checkSize(12, 8),
        checkDuplicates(currPlates),
        checkMaxCountRequests(24),
        checkMinCountRequests(1),
        checkAllSamplesInColumnsList(['1', '2', '3']),
        checkLibraryTypesInAllWells(this.libraryTypes),
        checkAllLibraryRequestsWithSameReadySubmissions(),
        checkPlateWithSameReadyLibrarySubmissions({}),
      ]
    },
    validateLibraryTypeForEveryRequest() {
      return this.validTransfers.every((transfer) => this.libraryTypes.includes(transfer.request.libraryType))
    },
  },
  methods: {
    apiTransfers() {
      return this.validTransfersByTargetPlate.reduce((memo, transfers) => {
        const library_type = transfers[0].request.library_type
        memo[library_type] = transferPlatesToPlatesCreator(transfers, this.transfersCreatorObj.extraParams)
        return memo
      }, {})
    },
    apiPayloads() {
      return Object.entries(this.apiTransfers()).map(([libraryType, transfers]) => {
        return {
          plate: {
            parent_uuid: this.validPlates[0].plate.uuid,
            purpose_uuid: this.childrenLibraryTypeToPurposeMapping[libraryType],
            transfers: transfers,
          },
        }
      })
    },
    createPlate() {
      this.progressMessage = 'Creating plates...'
      this.loading = true

      return Promise.all(
        this.apiPayloads().map((payload) => {
          return this.$axios({
            method: 'post',
            url: this.targetUrl,
            headers: { 'X-Requested-With': 'XMLHttpRequest' },
            data: payload,
          })
        }),
      )
        .then((responses) => {
          const response = responses[0]
          // Ajax responses automatically follow redirects, which
          // would result in us receiving the full HTML for the child
          // plate here, which we'd then need to inject into the
          // page, and update the history. Instead we don't redirect
          // application/json requests, and redirect the user ourselves.
          this.progressMessage = response.data.message
          this.locationObj.href = response.data.redirect
        })
        .catch((error) => {
          // Something has gone wrong
          handleFailedRequest(error)
          this.loading = false
        })
    },
  },
}
