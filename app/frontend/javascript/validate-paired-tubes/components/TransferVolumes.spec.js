import TransferVolumes from './TransferVolumes.vue'
import { mount } from '@vue/test-utils'

import { purposeConfigForTube } from '@/javascript/shared/tubeHelpers.js'
vi.mock('@/javascript/shared/tubeHelpers.js')

import {
  purposeTargetMolarityParameter,
  purposeTargetVolumeParameter,
  purposeMinimumPickParameter,
  tubeMostRecentMolarity,
  calculateTransferVolumes,
} from '@/javascript/shared/tubeTransferVolumes.js'
vi.mock('@/javascript/shared/tubeTransferVolumes.js')

describe('TransferVolumes', () => {
  const mockTube = {}
  const mockPurposeConfigs = {}
  const mockPurposeConfig = {}

  const wrapperFactory = function (options = {}) {
    return mount(TransferVolumes, {
      props: {
        purposeConfigs: mockPurposeConfigs,
        tube: mockTube,
        ...options,
      },
    })
  }

  describe('purposeConfig', () => {
    let wrapper

    beforeEach(() => {
      purposeConfigForTube.mockClear()

      purposeConfigForTube.mockReturnValue(mockPurposeConfig)
      wrapper = wrapperFactory()
    })

    it('calls purposeConfigForTube with expected arguments', () => {
      expect(purposeConfigForTube.mock.calls.length).toBe(1)
      expect(purposeConfigForTube.mock.calls[0][0]).toEqual(mockTube)
      expect(purposeConfigForTube.mock.calls[0][1]).toEqual(mockPurposeConfigs)
    })

    it('returns the expected purpose config', () => {
      expect(wrapper.vm.purposeConfig).toBe(mockPurposeConfig)
    })
  })

  describe('sourceMolarity', () => {
    let wrapper
    const sourceMolarity = 6

    beforeEach(() => {
      tubeMostRecentMolarity.mockClear()

      tubeMostRecentMolarity.mockReturnValue(sourceMolarity)
      wrapper = wrapperFactory()
    })

    it('calls purposeTargetVolumeParameter with expected arguments', () => {
      expect(tubeMostRecentMolarity.mock.calls.length).toBe(1)
      expect(tubeMostRecentMolarity.mock.calls[0][0]).toEqual(mockTube)
    })

    it('returns the expected target volume', () => {
      expect(wrapper.vm.sourceMolarity).toBe(sourceMolarity)
    })
  })

  describe('targetMolarity', () => {
    let wrapper
    const molarity = 250

    beforeEach(() => {
      purposeConfigForTube.mockClear()
      purposeTargetMolarityParameter.mockClear()

      purposeConfigForTube.mockReturnValue(mockPurposeConfig)
      purposeTargetMolarityParameter.mockReturnValue(molarity)
      wrapper = wrapperFactory()
    })

    it('calls purposeTargetMolarityParameter with expected arguments', () => {
      expect(purposeTargetMolarityParameter.mock.calls.length).toBe(1)
      expect(purposeTargetMolarityParameter.mock.calls[0][0]).toBe(mockPurposeConfig)
    })

    it('returns the expected target molarity', () => {
      expect(wrapper.vm.targetMolarity).toBe(molarity)
    })
  })

  describe('targetVolume', () => {
    let wrapper
    const volume = 250

    beforeEach(() => {
      purposeConfigForTube.mockClear()
      purposeTargetVolumeParameter.mockClear()

      purposeConfigForTube.mockReturnValue(mockPurposeConfig)
      purposeTargetVolumeParameter.mockReturnValue(volume)
      wrapper = wrapperFactory()
    })

    it('calls purposeTargetVolumeParameter with expected arguments', () => {
      expect(purposeTargetVolumeParameter.mock.calls.length).toBe(1)
      expect(purposeTargetVolumeParameter.mock.calls[0][0]).toBe(mockPurposeConfig)
    })

    it('returns the expected target volume', () => {
      expect(wrapper.vm.targetVolume).toBe(volume)
    })
  })

  describe('transferVolumes', () => {
    let wrapper
    const targetMolarity = 4
    const targetVolume = 192
    const minimumPick = 2
    const sourceMolarity = 8.0
    const mockTransferVolumes = {}

    beforeEach(() => {
      purposeConfigForTube.mockClear()
      purposeTargetMolarityParameter.mockClear()
      purposeTargetVolumeParameter.mockClear()
      purposeMinimumPickParameter.mockClear()
      tubeMostRecentMolarity.mockClear()
      calculateTransferVolumes.mockClear()

      purposeConfigForTube.mockReturnValue(mockPurposeConfig)
      purposeTargetMolarityParameter.mockReturnValue(targetMolarity)
      purposeTargetVolumeParameter.mockReturnValue(targetVolume)
      purposeMinimumPickParameter.mockReturnValue(minimumPick)
      tubeMostRecentMolarity.mockReturnValue(sourceMolarity)
      calculateTransferVolumes.mockReturnValue(mockTransferVolumes)
      wrapper = wrapperFactory()
    })

    it('calls tubeMostRecentMolarity with expected arguments', () => {
      expect(tubeMostRecentMolarity.mock.calls.length).toBe(1)
      expect(tubeMostRecentMolarity.mock.calls[0][0]).toEqual(mockTube)
    })

    it('calls purposeMinimumPickParameter with expected arguments', () => {
      expect(purposeMinimumPickParameter.mock.calls.length).toBe(1)
      expect(purposeMinimumPickParameter.mock.calls[0][0]).toBe(mockPurposeConfig)
    })

    it('calls calculateTransferVolumes with expected arguments', () => {
      expect(calculateTransferVolumes.mock.calls.length).toBe(1)
      expect(calculateTransferVolumes.mock.calls[0][0]).toBe(targetMolarity)
      expect(calculateTransferVolumes.mock.calls[0][1]).toBe(targetVolume)
      expect(calculateTransferVolumes.mock.calls[0][2]).toBe(sourceMolarity)
      expect(calculateTransferVolumes.mock.calls[0][3]).toBe(minimumPick)
    })

    it('returns the expected transfer volumes', () => {
      expect(wrapper.vm.transferVolumes).toBe(mockTransferVolumes)
    })
  })

  describe('sampleVolumeForDisplay', () => {
    let wrapper
    const transferVolumes = {
      sampleVolume: 150.12345,
      bufferVolume: 49.87655,
    }

    beforeEach(() => {
      calculateTransferVolumes.mockClear()

      calculateTransferVolumes.mockReturnValue(transferVolumes)
      wrapper = wrapperFactory()
    })

    it('returns the expected sample volume string', () => {
      expect(wrapper.vm.sampleVolumeForDisplay).toBe('150.12')
    })
  })

  describe('bufferVolumeForDisplay', () => {
    let wrapper
    const transferVolumes = {
      sampleVolume: 150.12345,
      bufferVolume: 49.87655,
    }

    beforeEach(() => {
      calculateTransferVolumes.mockReturnValue(transferVolumes)
      wrapper = wrapperFactory()
    })

    it('returns the expected buffer volume string', () => {
      expect(wrapper.vm.bufferVolumeForDisplay).toBe('49.88')
    })
  })

  describe('sourceMolarityForDisplay', () => {
    let wrapper
    const sourceMolarity = 3.4567

    beforeEach(() => {
      tubeMostRecentMolarity.mockClear()

      tubeMostRecentMolarity.mockReturnValue(sourceMolarity)
      wrapper = wrapperFactory()
    })

    it('returns the expected source molarity string', () => {
      expect(wrapper.vm.sourceMolarityForDisplay).toBe('3.46')
    })
  })

  describe('targetMolarityForDisplay', () => {
    let wrapper
    const molarity = 5.6789

    beforeEach(() => {
      purposeConfigForTube.mockClear()
      purposeTargetMolarityParameter.mockClear()

      purposeConfigForTube.mockReturnValue(mockPurposeConfig)
      purposeTargetMolarityParameter.mockReturnValue(molarity)
      wrapper = wrapperFactory()
    })

    it('returns the expected target molarity string', () => {
      expect(wrapper.vm.targetMolarityForDisplay).toBe('5.68')
    })
  })

  describe('targetVolumeForDisplay', () => {
    let wrapper
    const volume = 25.6789

    beforeEach(() => {
      purposeConfigForTube.mockClear()
      purposeTargetVolumeParameter.mockClear()

      purposeConfigForTube.mockReturnValue(mockPurposeConfig)
      purposeTargetVolumeParameter.mockReturnValue(volume)
      wrapper = wrapperFactory()
    })

    it('returns the expected target volume string', () => {
      expect(wrapper.vm.targetVolumeForDisplay).toBe('25.68')
    })
  })

  describe('belowTargetMolarity', () => {
    describe('is below target molarity', () => {
      let wrapper
      const transferVolumes = {
        belowTarget: true,
      }

      beforeEach(() => {
        calculateTransferVolumes.mockClear()

        calculateTransferVolumes.mockReturnValue(transferVolumes)
        wrapper = wrapperFactory()
      })

      it('returns the expected below target molarity value', () => {
        expect(wrapper.vm.belowTargetMolarity).toBe(true)
      })
    })

    describe('is not below target molarity', () => {
      let wrapper
      const transferVolumes = {
        belowTarget: false,
      }

      beforeEach(() => {
        calculateTransferVolumes.mockClear()

        calculateTransferVolumes.mockReturnValue(transferVolumes)
        wrapper = wrapperFactory()
      })

      it('returns the expected below target molarity value', () => {
        expect(wrapper.vm.belowTargetMolarity).toBe(false)
      })
    })
  })

  describe('readyToDisplayResult', () => {
    describe('no confirmed pair', () => {
      it('returns not ready', () => {
        purposeConfigForTube.mockReturnValue(mockPurposeConfig)
        const wrapper = wrapperFactory({ confirmedPair: false })
        expect(wrapper.vm.readyToDisplayResult).not.toBeTruthy()
      })
    })

    describe('no purpose config', () => {
      it('returns not ready', () => {
        purposeConfigForTube.mockReturnValue(undefined)
        const wrapper = wrapperFactory({ confirmedPair: true })
        expect(wrapper.vm.readyToDisplayResult).not.toBeTruthy()
      })
    })

    describe('purpose config and confirmed pair', () => {
      it('returns ready', () => {
        purposeConfigForTube.mockReturnValue(mockPurposeConfig)
        const wrapper = wrapperFactory({ confirmedPair: true })
        expect(wrapper.vm.readyToDisplayResult).toBeTruthy()
      })
    })
  })

  describe('not ready to display result', () => {
    it('renders a default message', () => {
      const wrapper = wrapperFactory()
      expect(wrapper.text()).toMatch(/transfer volumes will be shown here/)
    })
  })

  describe('ready to display result', () => {
    let wrapper
    const targetMolarity = 4
    const targetVolume = 192
    const transferVolumes = {
      sampleVolume: 150.12345,
      bufferVolume: 49.87655,
    }

    beforeEach(() => {
      purposeTargetMolarityParameter.mockClear()
      purposeTargetVolumeParameter.mockClear()
      calculateTransferVolumes.mockClear()

      purposeTargetMolarityParameter.mockReturnValue(targetMolarity)
      purposeTargetVolumeParameter.mockReturnValue(targetVolume)
      calculateTransferVolumes.mockReturnValue(transferVolumes)
      wrapper = wrapperFactory()
    })

    it('displays the target molarity', () => {
      expect(wrapper.text()).toMatch(/4.00 nM/)
    })

    // Have to use \u03BC in place of µ symbol because JavaScript regex doesn't like it

    it('displays the target volume', () => {
      expect(wrapper.text()).toMatch(/192.00 \u03BCl/)
    })

    it('displays the sample volume', () => {
      expect(wrapper.text()).toMatch(/Sample Volume.*150\.12 \u03BCl/)
    })

    it('displays the buffer volume', () => {
      expect(wrapper.text()).toMatch(/Buffer Volume.*49\.88 \u03BCl/)
    })
  })
})
