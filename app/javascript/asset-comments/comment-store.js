// Shared object for retrieval of comments from SequenceScape API

const commentStoreFactory = function (axiosInstance, devourApi, assetId, userId) {
  return {
    comments: undefined,

    async refreshComments() {
      this.comments = undefined
      this.comments = (await devourApi.one('labware', assetId).all('comment').get({ include: 'user' })).data
      return true
    },
    async addComment(newTitle, newDescription) {
      let payload = {
        data: {
          type: 'comments',
          attributes: {
            title: newTitle,
            description: newDescription,
          },
          relationships: {
            commentable: {
              data: { type: 'labware', id: assetId },
            },
            user: {
              data: { type: 'users', id: userId },
            },
          },
        },
      }

      await axiosInstance({
        method: 'post',
        url: 'comments',
        data: payload,
      })
        .then((response) => {
          // expecting 201 for comment added successfully
          if (!response.status === 201) {
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

      await this.refreshComments()

      return true
    },
  }
}

export default commentStoreFactory
