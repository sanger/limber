import devourApi from '@/javascript/shared/devourApi.js'
import resources from '@/javascript/shared/resources.js'
import axios from 'axios'
import commentStoreFactory from '@/javascript/asset-comments/comment-store.js'

const commentFactoryStores = {}

const createCommentFactory = (props) => {
  let commentFactoryStoreForAsset = commentFactoryStores[props.assetId]
  if (commentFactoryStoreForAsset && commentFactoryStoreForAsset.commentFactory) {
    commentFactoryStoreForAsset.refCount++
    return commentFactoryStoreForAsset.commentFactory
  }

  const sequencescapeApiUrl = props.sequencescapeApi
  const sequencescapeApiKey = props.sequencescapeApiKey
  const axiosInstance = axios.create({
    baseURL: sequencescapeApiUrl,
    timeout: 10000,
    headers: {
      Accept: 'application/vnd.api+json',
      'Content-Type': 'application/vnd.api+json',
    },
  })
  const api = devourApi({ apiUrl: sequencescapeApiUrl }, resources, sequencescapeApiKey)
  const commentFactory = commentStoreFactory(axiosInstance, api, props.assetId, props.userId)

  commentFactoryStores[props.assetId] = { commentFactory, refCount: 1 }
  return commentFactory
}

const removeCommentFactory = (assetId) => {
  if (commentFactoryStores[assetId]) {
    commentFactoryStores[assetId].refCount -= 1
    if (commentFactoryStores[assetId].refCount === 0) {
      delete commentFactoryStores[assetId]
    }
  }
}

export { createCommentFactory, removeCommentFactory, commentFactoryStores }
