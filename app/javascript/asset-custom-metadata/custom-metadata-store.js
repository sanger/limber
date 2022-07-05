// Shared object for retrieval of comments from SequenceScape API

const customMetadataStoreFactory = function (axiosInstance, devourApi, assetId) {
  return {
    customMetadata: undefined,
    customMetadatumCollectionsId: undefined,

    async refreshCustomMetadata() {
      this.customMetadata = undefined

      let response = await devourApi.request(
        `http://localhost:3000/api/v2/labware/${assetId}/custom_metadatum_collection`,
        'GET'
      )

      this.customMetadata = response.data.metadata
      this.customMetadatumCollectionsId = response.data.id
      return true
    },
    async addCustomMetadata(customMetadatumCollectionsId, customMetadata) {
      let payload = {
        data: {
          id: customMetadatumCollectionsId,
          type: 'custom_metadatum_collections',
          attributes: {
            metadata: customMetadata,
          },
        },
      }

      await axiosInstance({
        method: 'patch',
        url: `custom_metadatum_collections/${customMetadatumCollectionsId}`,
        data: payload,
      })
        .then((response) => {
          // expecting 200 for custom metadata patched successfully
          if (!response.status === 200) {
            console.error('Error on adding comment, unexpected response status: ', response.status)
            return false
          }
        })
        .catch(function (error) {
          if (error.response) {
            // The request was made and the server responded with a status code
            // that falls out of the range of 2xx
            console.error('Error on adding comment, unexpected response status code, details:')
            console.error(error.response.data)
            console.error(error.response.status)
            console.error(error.response.headers)
          } else if (error.request) {
            // The request was made but no response was received
            // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
            // http.ClientRequest in node.js
            console.error('Error on adding comment, no response from server:')
            console.error(error.request)
          } else {
            // Something happened in setting up the request that triggered an Error
            console.error('Error on adding comment, in request to axios:')
            console.error(error.message)
          }
          console.error(error.config)
          return false
        })

      await this.refreshCustomMetadata()

      return true
    },
  }
}

export default customMetadataStoreFactory
