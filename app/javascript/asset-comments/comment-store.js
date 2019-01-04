// Shared object for retrieval of comments from SequenceScape API
const commentStoreFactory = function(commentApi, assetId) {
  return {
    comments: undefined,

    async refreshComments() {
      this.comments = undefined
      this.comments = (
        await commentApi.includes({ comments: 'user' }).find(assetId)
      ).data.comments
      return true
    }
  }
}

export default commentStoreFactory
