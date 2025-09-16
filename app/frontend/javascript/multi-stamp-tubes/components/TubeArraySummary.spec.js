// Import the component being tested
import { mount } from '@vue/test-utils'
import TubeArraySummary from './TubeArraySummary.vue'

describe('TubeArraySummary', () => {
  let emptyTubes = []
  for (let i = 0; i < 96; i++) {
    emptyTubes.push({ index: i, labware: null, state: 'empty' })
  }

  let fullSetOfTubes = []
  for (let i = 0; i < 96; i++) {
    let machine_barcode = (1000000000000 + i).toString()
    let human_barcode = 'NT' + (1000 + i).toString() + 'G'
    fullSetOfTubes.push({
      index: i,
      labware: { labware_barcode: { human_barcode: human_barcode, machine_barcode: machine_barcode } },
      state: 'valid',
    })
  }

  let mixtureOfTubesWithDuplicates = []
  for (let i = 0; i < 96; i++) {
    let human_barcode, machine_barcode

    if (i < 6) {
      human_barcode = 'NT1001G'
      machine_barcode = '1000000000001'
    } else if (i < 12) {
      human_barcode = 'NT1002H'
      machine_barcode = '1000000000002'
    } else if (i < 18) {
      human_barcode = 'NT1003I'
      machine_barcode = '1000000000003'
    }

    if (human_barcode && machine_barcode) {
      mixtureOfTubesWithDuplicates.push({
        index: i.toString(),
        labware: { labware_barcode: { human_barcode, machine_barcode } },
        state: 'valid',
      })
    } else {
      mixtureOfTubesWithDuplicates.push({ index: i.toString(), labware: null, state: 'empty' })
    }
  }

  const mixtureOfTubesWithDifferingStates = []
  for (let i = 0; i < 96; i++) {
    switch (true) {
      case i < 6:
        mixtureOfTubesWithDifferingStates.push({
          index: i.toString(),
          labware: {
            labware_barcode: { human_barcode: 'PASSED', machine_barcode: '1000000000001' },
            state: 'passed',
          },
          state: 'valid',
        })
        break
      case i < 12:
        mixtureOfTubesWithDifferingStates.push({
          index: i.toString(),
          labware: {
            labware_barcode: { human_barcode: 'PENDING', machine_barcode: '1000000000002' },
            state: 'pending',
          },
          state: 'valid',
        })
        break
      case i < 18:
        mixtureOfTubesWithDifferingStates.push({
          index: i.toString(),
          labware: {
            labware_barcode: { human_barcode: 'UNKNOWN', machine_barcode: '1000000000003' },
            state: 'unknown',
          },
          state: 'valid',
        })
        break
      default:
        mixtureOfTubesWithDifferingStates.push({ index: i.toString(), labware: null, state: 'empty' })
        break
    }
  }

  const wrapperTubeArraySummaryEmpty = function () {
    return mount(TubeArraySummary, {
      props: {
        tubes: emptyTubes,
      },
    })
  }

  const wrapperTubeArraySummaryWithDuplicates = function () {
    return mount(TubeArraySummary, {
      props: {
        tubes: mixtureOfTubesWithDuplicates,
      },
    })
  }

  const wrapperTubeArraySummaryFull = function () {
    return mount(TubeArraySummary, {
      props: {
        tubes: fullSetOfTubes,
      },
    })
  }

  const wrapperTubeArraySummaryWithDifferingStates = function () {
    return mount(TubeArraySummary, {
      props: {
        tubes: mixtureOfTubesWithDifferingStates,
      },
    })
  }

  it('renders the provided caption', () => {
    const wrapper = wrapperTubeArraySummaryWithDuplicates()

    expect(wrapper.find('caption').text()).toEqual('Summary of scanned tubes')
  })

  it('renders the provided tubes summary headers', () => {
    const wrapper = wrapperTubeArraySummaryWithDuplicates()

    expect(wrapper.find('#header_tube_colour').text()).toEqual('Tube Colour')
    expect(wrapper.find('#header_human_barcode').text()).toEqual('Human Barcode')
    expect(wrapper.find('#header_machine_barcode').text()).toEqual('Machine Barcode')
    expect(wrapper.find('#header_replicates').text()).toEqual('Replicates')
  })

  it('renders the provided tubes summary rows', () => {
    const wrapper = wrapperTubeArraySummaryWithDuplicates()

    // row 1
    expect(wrapper.find('#row_human_barcode_index_0').text()).toEqual('NT1001G')
    expect(wrapper.find('#row_machine_barcode_index_0').text()).toEqual('1000000000001')
    expect(wrapper.find('#row_replicates_index_0').text()).toEqual('6')

    // row 2
    expect(wrapper.find('#row_human_barcode_index_1').text()).toEqual('NT1002H')
    expect(wrapper.find('#row_machine_barcode_index_1').text()).toEqual('1000000000002')
    expect(wrapper.find('#row_replicates_index_1').text()).toEqual('6')

    // row 3
    expect(wrapper.find('#row_human_barcode_index_2').text()).toEqual('NT1003I')
    expect(wrapper.find('#row_machine_barcode_index_2').text()).toEqual('1000000000003')
    expect(wrapper.find('#row_replicates_index_2').text()).toEqual('6')

    // row 4
    expect(wrapper.find('#row_human_barcode_index_3').text()).toEqual('Empty')
    expect(wrapper.find('#row_machine_barcode_index_3').text()).toEqual('Empty')
    expect(wrapper.find('#row_replicates_index_3').text()).toEqual('78')
  })

  it('only renders a row for the empty positions when there are no tubes', () => {
    const wrapper = wrapperTubeArraySummaryEmpty()

    // row 1
    expect(wrapper.find('#row_human_barcode_index_0').text()).toEqual('Empty')
    expect(wrapper.find('#row_machine_barcode_index_0').text()).toEqual('Empty')
    expect(wrapper.find('#row_replicates_index_0').text()).toEqual('96')
  })

  it('does not render a row for empty positions when there are none', () => {
    const wrapper = wrapperTubeArraySummaryFull()

    // row 1
    expect(wrapper.find('#row_human_barcode_index_0').text()).toEqual('NT1000G')
    expect(wrapper.find('#row_machine_barcode_index_0').text()).toEqual('1000000000000')
    expect(wrapper.find('#row_replicates_index_0').text()).toEqual('1')

    // row 96
    expect(wrapper.find('#row_human_barcode_index_95').text()).toEqual('NT1095G')
    expect(wrapper.find('#row_machine_barcode_index_95').text()).toEqual('1000000000095')
    expect(wrapper.find('#row_replicates_index_95').text()).toEqual('1')
  })

  it('renders tube summary rows based on labware state', () => {
    const wrapper = wrapperTubeArraySummaryWithDifferingStates()

    // row 1
    expect(wrapper.find('#row_tube_colour_index_0').element.children[0].classList.contains('colour-1')).toBe(true)
    expect(wrapper.find('#row_human_barcode_index_0').text()).toEqual('PASSED')
    expect(wrapper.find('#row_machine_barcode_index_0').text()).toEqual('1000000000001')
    expect(wrapper.find('#row_replicates_index_0').text()).toEqual('6')

    // row 2
    expect(wrapper.find('#row_tube_colour_index_1').element.children.length).toBe(0) // no colour should be rendered
    expect(wrapper.find('#row_human_barcode_index_1').text()).toEqual('PENDING')
    expect(wrapper.find('#row_machine_barcode_index_1').text()).toEqual('1000000000002')
    expect(wrapper.find('#row_replicates_index_1').text()).toEqual('6')

    // row 3
    expect(wrapper.find('#row_tube_colour_index_2').element.children.length).toBe(0) // no colour should be rendered
    expect(wrapper.find('#row_human_barcode_index_2').text()).toEqual('UNKNOWN')
    expect(wrapper.find('#row_machine_barcode_index_2').text()).toEqual('1000000000003')
    expect(wrapper.find('#row_replicates_index_2').text()).toEqual('6')

    // row 4
    expect(wrapper.find('#row_tube_colour_index_3').element.children.length).toBe(0) // empty
    expect(wrapper.find('#row_human_barcode_index_3').text()).toEqual('Empty')
    expect(wrapper.find('#row_machine_barcode_index_3').text()).toEqual('Empty')
    expect(wrapper.find('#row_replicates_index_3').text()).toEqual('78')
  })
})
