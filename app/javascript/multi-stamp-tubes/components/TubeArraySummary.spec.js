// Import the component being tested
import { mount } from '@vue/test-utils'
import TubeArraySummary from './TubeArraySummary.vue'

// create an extended `Vue` constructor
import localVue from 'test_support/base_vue'

describe('TubeArraySummary', () => {
  var emptyTubes = []
  for (let i = 0; i < 96; i++) {
    emptyTubes.push({ index: i, labware: null, state: 'empty' })
  }

  var fullSetOfTubes = []
  for (let i = 0; i < 96; i++) {
    var machine_barcode = (1000000000000 + i).toString()
    var human_barcode = 'NT' + (1000 + i).toString() + 'G'
    fullSetOfTubes.push({
      index: i,
      labware: { labware_barcode: { human_barcode: human_barcode, machine_barcode: machine_barcode } },
      state: 'valid',
    })
  }

  var mixtureOfTubesWithDuplicates = []
  for (let i = 0; i < 96; i++) {
    switch (true) {
      case i < 6:
        var human_barcode1 = 'NT1001G'
        var machine_barcode1 = '1000000000001'
        mixtureOfTubesWithDuplicates.push({
          index: i.toString(),
          labware: { labware_barcode: { human_barcode: human_barcode1, machine_barcode: machine_barcode1 } },
          state: 'valid',
        })
        break
      case i < 12:
        var human_barcode2 = 'NT1002H'
        var machine_barcode2 = '1000000000002'
        mixtureOfTubesWithDuplicates.push({
          index: i.toString(),
          labware: { labware_barcode: { human_barcode: human_barcode2, machine_barcode: machine_barcode2 } },
          state: 'valid',
        })
        break
      case i < 18:
        var human_barcode3 = 'NT1003I'
        var machine_barcode3 = '1000000000003'
        mixtureOfTubesWithDuplicates.push({
          index: i.toString(),
          labware: { labware_barcode: { human_barcode: human_barcode3, machine_barcode: machine_barcode3 } },
          state: 'valid',
        })
        break
      default:
        mixtureOfTubesWithDuplicates.push({ index: i.toString(), labware: null, state: 'empty' })
        break
    }
  }

  const wrapperTubeArraySummaryEmpty = function () {
    return mount(TubeArraySummary, {
      propsData: {
        tubes: emptyTubes,
      },
      localVue,
    })
  }

  const wrapperTubeArraySummaryWithDuplicates = function () {
    return mount(TubeArraySummary, {
      propsData: {
        tubes: mixtureOfTubesWithDuplicates,
      },
      localVue,
    })
  }

  const wrapperTubeArraySummaryFull = function () {
    return mount(TubeArraySummary, {
      propsData: {
        tubes: fullSetOfTubes,
      },
      localVue,
    })
  }
  it('renders the provided caption', () => {
    const wrapper = wrapperTubeArraySummaryWithDuplicates()

    expect(wrapper.find('caption').text()).toEqual('Summary of scanned tubes')
  })

  it('renders the provided tubes summary headers', () => {
    const wrapper = wrapperTubeArraySummaryWithDuplicates()

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
})
