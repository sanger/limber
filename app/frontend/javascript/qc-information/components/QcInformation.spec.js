// Import the component being tested
import { mount } from '@vue/test-utils'
import { flushPromises } from '@vue/test-utils'

import QcInformation from './QcInformation.vue'
describe('QcInformation', () => {
  const wrapperFactory = function () {
    return mount(QcInformation, {
      props: {
        assetUuid: 'test',
      },
      global: {
        stubs: {
          'lb-qc-field': true,
        },
      },
    })
  }

  it('updates its data as values change', () => {
    let wrapper = wrapperFactory()

    let volumeAttributes = {
      value: '1.5',
      assay_type: 'Volume Check',
      units: 'ul',
      key: 'volume',
      assay_version: 'manual',
    }
    let molarityAttributes = {
      value: '10',
      assay_type: 'Estimated',
      units: 'nM',
      key: 'molarity',
      assay_version: 'manual',
    }
    wrapper.find('lb-qc-field-stub[name="volume"]').trigger('change', volumeAttributes)
    wrapper.find('lb-qc-field-stub[name="molarity"]').trigger('change', molarityAttributes)

    expect(wrapper.vm.qcResults.volume).toEqual(expect.objectContaining(volumeAttributes))
    expect(wrapper.vm.qcResults.molarity).toEqual(expect.objectContaining(molarityAttributes))
  })

  it('filters empty values', () => {
    let wrapper = wrapperFactory()
    let fullAttributes = {
      value: '1.5',
      assay_type: 'Volume Check',
      units: 'ul',
      key: 'volume',
      assay_version: 'manual',
    }
    let emptyAttributes = {
      value: '',
      assay_type: 'Estimated',
      units: 'nM',
      key: 'molarity',
      assay_version: 'manual',
    }
    wrapper.setData({
      qcResults: { volume: fullAttributes, molarity: emptyAttributes },
    })

    expect(wrapper.vm.filledQcResults).toEqual([fullAttributes])
  })

  it('submits a qc result on click', async () => {
    const wrapper = wrapperFactory()
    const fullAttributes = {
      value: '1.5',
      assay_type: 'Volume Check',
      units: 'ul',
      key: 'volume',
      assay_version: 'manual',
      uuid: 'test',
    }
    const emptyAttributes = {
      value: '',
      assay_type: 'Estimated',
      units: 'nM',
      key: 'molarity',
      assay_version: 'manual',
      uuid: 'test',
    }
    const expectedPayload = {
      data: {
        type: 'qc_assays',
        attributes: {
          qc_results: [
            {
              value: '1.5',
              assay_type: 'Volume Check',
              units: 'ul',
              key: 'volume',
              assay_version: 'manual',
              uuid: 'test',
            },
          ],
        },
      },
    }

    wrapper.vm.axiosInstance = vi.fn().mockResolvedValue({
      data: {},
    })

    wrapper.setData({
      qcResults: { volume: fullAttributes, molarity: emptyAttributes },
    })

    // Triggering events on bootstrap stuff is currently unnecessarily painful
    wrapper.vm.submit()

    await flushPromises()

    expect(wrapper.vm.axiosInstance).toHaveBeenCalledTimes(1)
    expect(wrapper.vm.axiosInstance).toHaveBeenCalledWith({
      method: 'post',
      url: 'qc_assays',
      data: expectedPayload
    })
    expect(wrapper.vm.buttonStyle).toEqual('success')
  })
})
