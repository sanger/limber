import { mount } from '@vue/test-utils'
import ManualUltimaTagLayout from './ManualUltimaTagLayout.vue'

describe('ManualUltimaTagLayout', () => {
  const makeWrapper = (props = {}) =>
    mount(ManualUltimaTagLayout, {
      props: { api: {}, ...props },
      global: {
        stubs: {
          TagSetsLookup: {
            name: 'TagSetsLookup',
            props: ['filter'],
            template: '<div />',
          },
        },
      },
    })

  it('filters tag sets by Ultima adapter type and has no scan control', () => {
    const wrapper = makeWrapper()
    expect(wrapper.findComponent({ name: 'TagSetsLookup' }).props('filter')).toEqual({
      tag_group_adapter_type_name: 'null',
    })
    expect(wrapper.findComponent({ name: 'LabwareScan' }).exists()).toBe(false)
  })

  it('keeps separately named versions and emits the selected groups without a plate', async () => {
    const wrapper = makeWrapper()
    const group = { uuid: 'p1', name: 'P1 primer', tags: [{ index: 1, oligo: 'ACGT' }] }
    wrapper.vm.tagSetsLookupUpdated({
      state: 'valid',
      results: {
        first: { id: 'first', name: 'Ultima P1', tag_group: { ...group, uuid: 'p1' } },
        second: { id: 'second', name: 'Ultima P2', tag_group: group },
      },
    })
    await wrapper.setData({ tagSetId: 'second' })
    wrapper.vm.tagOffsetChanged(2)
    expect(wrapper.vm.coreTagSetOptions).toHaveLength(2)
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0]).toMatchObject({
      tagPlate: null,
      tag1Group: group,
      offsetTagsBy: 2,
      walkingBy: 'manual by plate',
      direction: 'column',
    })
    await wrapper.setData({ tagSetId: null })
    expect(wrapper.vm.tag1Group.tags).toEqual([])
  })

  it('keeps configured names visible while looking up their tag data', async () => {
    const wrapper = makeWrapper({ tagSets: ['Ultima P2', 'Ultima P1'] })
    expect(wrapper.findComponent({ name: 'TagSetsLookup' }).exists()).toBe(true)
    expect(wrapper.vm.tagSetOptions).toEqual([
      { value: null, text: 'Please select a Tagset...' },
      { value: 'Ultima P2', text: 'Ultima P2' },
      { value: 'Ultima P1', text: 'Ultima P1' },
    ])
    await wrapper.find('#ultima_tag_set').setValue('Ultima P1')
    expect(wrapper.vm.tagSetId).toBe('Ultima P1')
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0]).toMatchObject({
      tag1Group: { uuid: null, tags: [] },
      tag2Group: { uuid: null, tags: [] },
    })
    expect(wrapper.find('dl').exists()).toBe(false)

    const tagGroup = { uuid: 'p1', name: 'P1', tags: [{ index: 1, oligo: 'ACGT' }] }
    wrapper.findComponent({ name: 'TagSetsLookup' }).vm.$emit('change', {
      state: 'valid',
      results: {
        first: { id: 'first', name: 'Ultima P1', tag_group: tagGroup },
        second: { id: 'second', name: 'Unconfigured tag set', tag_group: { ...tagGroup, uuid: 'other' } },
      },
    })
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0]).toMatchObject({
      tag1Group: tagGroup,
      tag2Group: { uuid: null, tags: [] },
    })
    expect(wrapper.vm.coreTagSetOptions).toEqual([
      { value: 'Ultima P2', text: 'Ultima P2' },
      { value: 'Ultima P1', text: 'Ultima P1' },
    ])

    await wrapper.setProps({ tagSets: [] })
    expect(wrapper.vm.coreTagSetOptions).toEqual([])
    await wrapper.setProps({ tagSets: ['Missing tag set'] })
    expect(wrapper.vm.coreTagSetOptions).toEqual([{ value: 'Missing tag set', text: 'Missing tag set' }])
  })
})
