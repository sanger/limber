// Shared object for retrieval of comments from SequenceScape API

const commentStoreFactory = function(axiosInstance, commentApi, assetId, userId) {
  return {
    comments: undefined,

    async refreshComments() {
      this.comments = undefined
      this.comments = (
        await commentApi.includes({ comments: 'user' }).find(assetId)
      ).data.comments
      return true
    },
    async addComment(newTitle, newDescription) {
      let payload = { 'data': {
        'type': 'comments',
        'attributes': {
          'title': newTitle,
          'description': newDescription
        },
        'relationships': {
          'commentable': {
            'data': { 'type': 'assets', 'id': assetId }
          },
          'user': {
            'data': { 'type': 'users', 'id': userId }
          }
        }
      }}

      await axiosInstance({
        method: 'post',
        url:'comments',
        data: payload
      }).then((response)=>{
        // expecting 201 for comment added successfully
        if(!response.status === 201) {
          console.log('Error on adding comment, unexpected response status: ', response.status)
        }
      }).catch(function (error) {
        if (error.response) {
          // The request was made and the server responded with a status code
          // that falls out of the range of 2xx
          console.log('Error on adding comment, unexpected response status code, details:')
          console.log(error.response.data)
          console.log(error.response.status)
          console.log(error.response.headers)
        } else if (error.request) {
          // The request was made but no response was received
          // `error.request` is an instance of XMLHttpRequest in the browser and an instance of
          // http.ClientRequest in node.js
          console.log('Error on adding comment, no response from server:')
          console.log(error.request)
        } else {
          // Something happened in setting up the request that triggered an Error
          console.log('Error on adding comment, in request to axios:')
          console.log(error.message)
        }
        console.log(error.config)
        return false
      })

      await this.refreshComments()

      return true
    }
  }
}

export default commentStoreFactory
