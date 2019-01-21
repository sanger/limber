// // Import the component being tested
import cookieJar from './cookieJar'

describe('cookieJar', () => {

  it('converts a cookie string to an object', () => {
    let cookie = 'key1=value1; key2=value=2;key3=value3'

    expect(cookieJar(cookie)).toEqual({
      key1: 'value1',
      key2: 'value=2',
      key3: 'value3'
    })
  })
})
