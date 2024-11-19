import devourApi from '@/javascript/shared/devourApi.js'
import resources from '@/javascript/shared/resources.js'
import commentStoreFactory from '@/javascript/asset-comments/comment-store.js'
import axios from 'axios'

const createCommentFactory = (props) => {
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
  const commentFactory = commentStoreFactory(axiosInstance, api, props.assetId, props.user_id)
  return commentFactory
}

export default createCommentFactory;
