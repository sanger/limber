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
        // TODO: what to do with response
        this.refreshComments()
      }).catch((error)=>{
        // TODO: what to do with error
        // console.log(error)
        return false
      })

      await this.refreshComments()

      return true
    }
  }
}

export default commentStoreFactory
