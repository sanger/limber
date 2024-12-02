import {
  createCommentFactory,
  removeCommentFactory,
  commentFactoryStores,
} from '@/javascript/asset-comments/comment-store-helpers.js'
import devourApi from '@/javascript/shared/devourApi.js'
import resources from '@/javascript/shared/resources.js'
import commentStoreFactory from '@/javascript/asset-comments/comment-store.js'
import axios from 'axios'

vi.mock('axios')
vi.mock('@/javascript/shared/devourApi.js')
vi.mock('@/javascript/asset-comments/comment-store.js')

describe('commentFactory', () => {
  let mockAxiosInstance
  let mockDevourApi
  let mockCommentFactory

  beforeEach(() => {
    mockAxiosInstance = {
      create: vi.fn().mockReturnValue({
        baseURL: 'http://example.com/api',
        timeout: 10000,
        headers: {
          Accept: 'application/vnd.api+json',
          'Content-Type': 'application/vnd.api+json',
        },
      }),
    }
    axios.create.mockReturnValue(mockAxiosInstance)

    mockDevourApi = vi.fn()
    devourApi.mockReturnValue(mockDevourApi)

    mockCommentFactory = {}
    commentStoreFactory.mockReturnValue(mockCommentFactory)
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('creates a new commentFactory and stores it', () => {
    const props = {
      sequencescapeApi: 'http://example.com/api',
      sequencescapeApiKey: 'test-api-key',
      assetId: '123',
      userId: 'user_id',
    }

    const result = createCommentFactory(props)

    expect(axios.create).toHaveBeenCalledWith({
      baseURL: props.sequencescapeApi,
      timeout: 10000,
      headers: {
        Accept: 'application/vnd.api+json',
        'Content-Type': 'application/vnd.api+json',
      },
    })
    expect(devourApi).toHaveBeenCalledWith({ apiUrl: props.sequencescapeApi }, resources, props.sequencescapeApiKey)
    expect(commentStoreFactory).toHaveBeenCalledWith(mockAxiosInstance, mockDevourApi, props.assetId, props.userId)
    expect(result).toBe(mockCommentFactory)
    expect(commentFactoryStores[props.assetId]).toEqual({ commentFactory: mockCommentFactory, refCount: 1 })
  })

  it('returns an existing commentFactory and increments the refCount', () => {
    const props = {
      sequencescapeApi: 'http://example.com/api',
      sequencescapeApiKey: 'test-api-key',
      assetId: '123',
      userId: 'user_id',
    }

    commentFactoryStores[props.assetId] = { commentFactory: mockCommentFactory, refCount: 1 }

    const result = createCommentFactory(props)

    expect(result).toBe(mockCommentFactory)
    expect(commentFactoryStores[props.assetId].refCount).toBe(2)
    expect(commentStoreFactory).not.toHaveBeenCalled()
  })

  it('removes a commentFactory when refCount drops to zero', () => {
    const assetId = '123'
    commentFactoryStores[assetId] = { commentFactory: mockCommentFactory, refCount: 1 }

    removeCommentFactory(assetId)

    expect(commentFactoryStores[assetId]).toBeUndefined()
  })

  it('decrements the refCount without removing the commentFactory', () => {
    const assetId = '123'
    commentFactoryStores[assetId] = { commentFactory: mockCommentFactory, refCount: 2 }

    removeCommentFactory(assetId)

    expect(commentFactoryStores[assetId].refCount).toBe(1)
  })
})
