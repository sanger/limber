// Import the component being tested
import { mount } from '@vue/test-utils'
import PairTubesToBlend from '@/javascript/blended-tube/components/PairTubesToBlend.vue'
import mockApi from '@/javascript/test_support/mock_api.js'

import { expect } from 'vitest'

describe('PairTubesToBlend.vue', () => {
  let wrapper

  const mockPairedTubes = [
    {
      labware: {
        labware_barcode: { human_barcode: 'TUBE1' },
        purpose: { name: 'Tube Purpose 1' },
        receptacle: {
          aliquots: [{ sample: { id: 1, name: 'Sample A' } }, { sample: { id: 2, name: 'Sample B' } }],
        },
        ancestors: [
          { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
        ],
      },
      state: 'valid',
    },
    {
      labware: {
        labware_barcode: { human_barcode: 'TUBE2' },
        purpose: { name: 'Tube Purpose 2' },
        receptacle: {
          aliquots: [{ sample: { id: 2, name: 'Sample B' } }, { sample: { id: 3, name: 'Sample C' } }],
        },
        ancestors: [
          { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
        ],
      },
      state: 'valid',
    },
  ]

  beforeEach(() => {
    wrapper = mount(PairTubesToBlend, {
      propsData: {
        acceptableParentTubePurposesArray: ['Tube Purpose 1', 'Tube Purpose 2'],
        singleAncestorParentTubePurpose: 'Tube Purpose 1',
        ancestorLabwarePurposeName: 'Ancestor Purpose Name',
        api: mockApi().devour,
      },
      data() {
        return {
          pairedTubes: mockPairedTubes,
          state: 'valid',
          errorMessages: [],
        }
      },
    })
  })

  // Test for validatedTubes
  it('validatedTubes should return true when both tubes are scanned and valid', () => {
    expect(wrapper.vm.validatedTubes()).toBe(true)
  })

  it('validatedTubes should return false when one or both tubes are not valid', () => {
    wrapper.setData({
      pairedTubes: [
        { labware: null, state: 'invalid' },
        { labware: null, state: 'invalid' },
      ],
    })
    expect(wrapper.vm.validatedTubes()).toBe(false)
  })

  // Test for findSharedAncestor
  it('findSharedAncestor should return the shared ancestor when it exists', () => {
    const sharedAncestor = wrapper.vm.findSharedAncestor()
    expect(sharedAncestor).toEqual({
      id: 1,
      labware_barcode: { human_barcode: 'PLATE1' },
      purpose: { name: 'Ancestor Purpose Name' },
    })
  })

  it('findSharedAncestor should return null when no shared ancestor exists', () => {
    wrapper.setData({
      pairedTubes: [
        {
          labware: {
            labware_barcode: { human_barcode: 'TUBE2' },
            purpose: { name: 'Tube Purpose 2' },
            receptacle: {
              aliquots: [{ sample: { id: 2, name: 'Sample B' } }],
            },
            ancestors: [
              { id: 2, labware_barcode: { human_barcode: 'PLATE2' }, purpose: { name: 'Ancestor Purpose Name' } },
            ],
          },
          state: 'valid',
        },
        {
          labware: {
            labware_barcode: { human_barcode: 'TUBE3' },
            purpose: { name: 'Tube Purpose 1' },
            receptacle: {
              aliquots: [{ sample: { id: 3, name: 'Sample C' } }],
            },
            ancestors: [
              { id: 3, labware_barcode: { human_barcode: 'PLATE3' }, purpose: { name: 'Ancestor Purpose Name' } },
            ],
          },
          state: 'valid',
        },
      ],
    })
    expect(wrapper.vm.findSharedAncestor()).toBeNull()
  })

  // Test for extractSampleIds
  it('extractSampleIds should return sample IDs from a tube', () => {
    const sampleIds = wrapper.vm.extractSampleIds(mockPairedTubes[0], 0)
    expect(sampleIds).toEqual([1, 2])
  })

  it('extractSampleIds should return an empty array if no aliquots are present', () => {
    const sampleIds = wrapper.vm.extractSampleIds({ labware: null }, 0)
    expect(sampleIds).toEqual([])
  })

  // Test for tubesHaveMatchingSamples
  it('tubesHaveMatchingSamples should return true when there are shared sample IDs', () => {
    expect(wrapper.vm.tubesHaveMatchingSamples).toBe(true)
  })

  it('tubesHaveMatchingSamples should return false when there are no shared sample IDs', () => {
    wrapper.setData({
      pairedTubes: [
        {
          labware: {
            labware_barcode: { human_barcode: 'TUBE1' },
            purpose: { name: 'Tube Purpose 1' },
            receptacle: {
              aliquots: [{ sample: { id: 1, name: 'Sample A' } }],
            },
            ancestors: [
              { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
            ],
          },
          state: 'valid',
        },
        {
          labware: {
            labware_barcode: { human_barcode: 'TUBE2' },
            purpose: { name: 'Tube Purpose 2' },
            receptacle: {
              aliquots: [{ sample: { id: 2, name: 'Sample B' } }],
            },
            ancestors: [
              { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
            ],
          },
          state: 'valid',
        },
      ],
    })
    expect(wrapper.vm.tubesHaveMatchingSamples).toBe(false)
  })

  // Test for matchedSamplesSummary
  it('matchedSamplesSummary should return the correct summary of matched samples', () => {
    expect(wrapper.vm.matchedSamplesSummary).toBe('1 of 3 samples match')
  })

  it('matchedSamplesSummary should return "valid pairing required first" if tubes are not valid', () => {
    wrapper.setData({
      pairedTubes: [
        { labware: null, state: 'invalid' },
        { labware: null, state: 'invalid' },
      ],
    })
    expect(wrapper.vm.matchedSamplesSummary).toBe('valid pairing required first')
  })

  describe('performPairingValidations', () => {
    it('should set state to "empty" if no tubes are scanned', () => {
      wrapper.setData({
        pairedTubes: [
          { labware: null, state: 'empty' },
          { labware: null, state: 'empty' },
        ],
      })

      wrapper.vm.performPairingValidations()

      expect(wrapper.vm.state).toBe('empty')
      expect(wrapper.vm.errorMessages).toEqual([])
    })

    it('should set state to "warning" if only one tube is scanned', () => {
      wrapper.setData({
        pairedTubes: [
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE1' },
              purpose: { name: 'Tube Purpose 1' },
            },
            state: 'valid',
          },
          { labware: null, state: 'empty' },
        ],
      })

      wrapper.vm.performPairingValidations()

      expect(wrapper.vm.state).toBe('warning')
      expect(wrapper.vm.errorMessages).toEqual([])
    })

    it('should set state to "invalid" if one or more tubes are invalid', () => {
      wrapper.setData({
        pairedTubes: [
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE1' },
              purpose: { name: 'Tube Purpose 1' },
            },
            state: 'invalid',
          },
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE2' },
              purpose: { name: 'Tube Purpose 2' },
            },
            state: 'valid',
          },
        ],
      })

      wrapper.vm.performPairingValidations()

      expect(wrapper.vm.state).toBe('invalid')
      expect(wrapper.vm.errorMessages).toContain('One or more tube is invalid')
    })

    it('should set state to "invalid" if tubes do not share a common ancestor', () => {
      wrapper.setData({
        pairedTubes: [
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE1' },
              purpose: { name: 'Tube Purpose 1' },
              ancestors: [
                { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE2' },
              purpose: { name: 'Tube Purpose 2' },
              ancestors: [
                { id: 2, labware_barcode: { human_barcode: 'PLATE2' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
        ],
      })

      wrapper.vm.performPairingValidations()

      expect(wrapper.vm.state).toBe('invalid')
      expect(wrapper.vm.errorMessages).toContain('The tubes do not share a common ancestor')
    })

    it('should set state to "invalid" if tubes do not share any matching samples', () => {
      wrapper.setData({
        pairedTubes: [
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE1' },
              purpose: { name: 'Tube Purpose 1' },
              receptacle: {
                aliquots: [{ sample: { id: 1, name: 'Sample A' } }],
              },
              ancestors: [
                { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE2' },
              purpose: { name: 'Tube Purpose 2' },
              receptacle: {
                aliquots: [{ sample: { id: 2, name: 'Sample B' } }],
              },
              ancestors: [
                { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
        ],
      })

      wrapper.vm.performPairingValidations()

      expect(wrapper.vm.state).toBe('invalid')
      expect(wrapper.vm.errorMessages).toContain('The tubes do not share any of the same samples')
    })

    it('should set state to "valid" if all validations pass', () => {
      wrapper.setData({
        pairedTubes: [
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE1' },
              purpose: { name: 'Tube Purpose 1' },
              receptacle: {
                aliquots: [{ sample: { id: 1, name: 'Sample A' } }, { sample: { id: 2, name: 'Sample B' } }],
              },
              ancestors: [
                { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE2' },
              purpose: { name: 'Tube Purpose 2' },
              receptacle: {
                aliquots: [{ sample: { id: 2, name: 'Sample B' } }, { sample: { id: 3, name: 'Sample C' } }],
              },
              ancestors: [
                { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
        ],
      })

      wrapper.vm.performPairingValidations()

      expect(wrapper.vm.state).toBe('valid')
      expect(wrapper.vm.errorMessages).toEqual([])
    })
  })

  describe('findAncestors', () => {
    it('should return ancestors for each tube when they exist', () => {
      const ancestors = wrapper.vm.findAncestors()

      expect(ancestors).toEqual([
        [{ id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } }],
        [{ id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } }],
      ])
    })

    it('should return an empty array for a tube with no ancestors', () => {
      wrapper.setData({
        pairedTubes: [
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE1' },
              purpose: { name: 'Tube Purpose 1' },
              ancestors: [],
            },
            state: 'valid',
          },
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE2' },
              purpose: { name: 'Tube Purpose 2' },
              ancestors: [
                { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
        ],
      })

      const ancestors = wrapper.vm.findAncestors()

      expect(ancestors).toEqual([
        [],
        [{ id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } }],
      ])
    })

    it('should return an empty array if ancestors are missing', () => {
      wrapper.setData({
        pairedTubes: [
          // Tube with no ancestors
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE1' },
              purpose: { name: 'Tube Purpose 1' },
              ancestors: [],
            },
            state: 'valid',
          },
          // Tube with ancestors
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE2' },
              purpose: { name: 'Tube Purpose 2' },
              ancestors: [
                { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
        ],
      })

      const ancestors = wrapper.vm.findAncestors()

      expect(ancestors).toEqual([
        [],
        [{ id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } }],
      ])
      expect(wrapper.vm.errorMessages).toContain(
        'Tube with purpose: "Tube Purpose 1" does not appear to have any ancestors. Cannot confirm if safe to blend.',
      )
    })

    it('should push an error message if a tube with a specific purpose does not have exactly one ancestor', () => {
      wrapper.setData({
        pairedTubes: [
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE1' },
              purpose: { name: 'Tube Purpose 1' },
              ancestors: [
                { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
                { id: 2, labware_barcode: { human_barcode: 'PLATE2' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
          {
            labware: {
              labware_barcode: { human_barcode: 'TUBE2' },
              purpose: { name: 'Tube Purpose 2' },
              ancestors: [
                { id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } },
              ],
            },
            state: 'valid',
          },
        ],
      })

      const ancestors = wrapper.vm.findAncestors()

      expect(ancestors).toEqual([
        [],
        [{ id: 1, labware_barcode: { human_barcode: 'PLATE1' }, purpose: { name: 'Ancestor Purpose Name' } }],
      ])
      expect(wrapper.vm.errorMessages).toContain(
        'Tube with purpose: "Tube Purpose 1" must have exactly one ancestor plate of purpose: "Ancestor Purpose Name". Found: PLATE1, PLATE2',
      )
    })

    it('should return an empty array if pairedTubes is empty', () => {
      wrapper.setData({
        pairedTubes: [],
      })

      const ancestors = wrapper.vm.findAncestors()

      expect(ancestors).toEqual([])
    })
  })

  describe('updateTube', () => {
    it('should update the tube at the specified index with the provided data', () => {
      const newTubeData = {
        labware: {
          labware_barcode: { human_barcode: 'NEW_TUBE' },
          purpose: { name: 'New Tube Purpose' },
          receptacle: {
            aliquots: [{ sample: { id: 99, name: 'New Sample' } }],
          },
          ancestors: [
            { id: 99, labware_barcode: { human_barcode: 'NEW_PLATE' }, purpose: { name: 'Ancestor Purpose Name' } },
          ],
        },
        state: 'valid',
      }

      // Update the tube at index 0
      wrapper.vm.updateTube(0, newTubeData)

      // Verify the tube at index 0 was updated properly
      expect(wrapper.vm.pairedTubes[0].labware.labware_barcode.human_barcode).toBe('NEW_TUBE')
      expect(wrapper.vm.pairedTubes[0].state).toBe('valid')
      expect(wrapper.vm.pairedTubes[0].index).toBe(0) // Verify index was added to the object

      // Verify the tube at index 1 was not modified
      expect(wrapper.vm.pairedTubes[1].labware.labware_barcode.human_barcode).toBe('TUBE2')
    })
  })

  describe('Computed Properties', () => {
    describe('colorForState', () => {
      it('returns grey for empty state', () => {
        wrapper.setData({ state: 'empty' })
        expect(wrapper.vm.colorForState).toBe('grey')
      })

      it('returns orange for warning state', () => {
        wrapper.setData({ state: 'warning' })
        expect(wrapper.vm.colorForState).toBe('orange')
      })

      it('returns red for invalid state', () => {
        wrapper.setData({ state: 'invalid' })
        expect(wrapper.vm.colorForState).toBe('red')
      })

      it('returns green for valid state', () => {
        wrapper.setData({ state: 'valid' })
        expect(wrapper.vm.colorForState).toBe('green')
      })

      it('returns gray for unknown state', () => {
        wrapper.setData({ state: 'unknown' })
        expect(wrapper.vm.colorForState).toBe('gray')
      })
    })

    describe('stateMessage', () => {
      it('returns correct message for empty state', () => {
        wrapper.setData({ state: 'empty' })
        expect(wrapper.vm.stateMessage).toBe('Awaiting tube scans...')
      })

      it('returns correct message for warning state', () => {
        wrapper.setData({ state: 'warning' })
        expect(wrapper.vm.stateMessage).toBe('Scan the other tube...')
      })

      it('returns correct message for invalid state', () => {
        wrapper.setData({ state: 'invalid', errorMessages: ['Error 1', 'Error 2'] })
        expect(wrapper.vm.stateMessage).toBe('Invalid: Error 1, Error 2')
      })

      it('returns correct message for valid state', () => {
        wrapper.setData({ state: 'valid' })
        expect(wrapper.vm.stateMessage).toBe('Valid Pairing!')
      })

      it('returns correct message for unknown state', () => {
        wrapper.setData({ state: 'unknown' })
        expect(wrapper.vm.stateMessage).toBe('Unknown state...')
      })
    })

    describe('stateMessageClass', () => {
      it('returns correct class for empty state', () => {
        wrapper.setData({ state: 'empty' })
        expect(wrapper.vm.stateMessageClass).toBe('color-black')
      })

      it('returns correct class for warning state', () => {
        wrapper.setData({ state: 'warning' })
        expect(wrapper.vm.stateMessageClass).toBe('color-orange')
      })

      it('returns correct class for invalid state', () => {
        wrapper.setData({ state: 'invalid' })
        expect(wrapper.vm.stateMessageClass).toBe('color-red')
      })

      it('returns correct class for valid state', () => {
        wrapper.setData({ state: 'valid' })
        expect(wrapper.vm.stateMessageClass).toBe('color-green')
      })

      it('returns correct class for unknown state', () => {
        wrapper.setData({ state: 'unknown' })
        expect(wrapper.vm.stateMessageClass).toBe('color-black')
      })
    })
  })
})
