import { mount, shallowMount } from '@vue/test-utils'
import ManualUltimaTagLayout from './ManualUltimaTagLayout.vue'
import ManualUltimaTaggedPlate from './ManualUltimaTaggedPlate.vue'

describe('ManualUltimaTaggedPlate tag set configuration', () => {
  it('decodes the page configuration and passes it to the manual controls', () => {
    const wrapper = shallowMount(ManualUltimaTaggedPlate, {
      props: { tagSets: JSON.stringify(['Ultima P1 v1', 'Ultima P1 v2']) },
      global: {
        stubs: {
          CustomTaggedPlate: {
            template:
              '<slot name="tag-layout-controls" :api="{}" :number-of-tags="0" :number-of-target-wells="0" :tags-per-well="1" />',
          },
        },
      },
    })
    expect(wrapper.findComponent(ManualUltimaTagLayout).props('tagSets')).toEqual(['Ultima P1 v1', 'Ultima P1 v2'])
  })
})

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
      tag_group_adapter_type_name: 'Ultima',
    })
    expect(wrapper.findComponent({ name: 'LabwareScan' }).exists()).toBe(false)
  })

  it('keeps separately named versions and emits the selected groups without a plate', async () => {
    const wrapper = makeWrapper()
    const group = { uuid: 'p1-v2', name: 'P1 primer version 2', tags: [{ index: 1, oligo: 'ACGT' }] }
    wrapper.vm.tagSetsLookupUpdated({
      state: 'valid',
      results: {
        first: { id: 'first', name: 'Ultima P1 version 1', tag_group: { ...group, uuid: 'p1-v1' } },
        second: { id: 'second', name: 'Ultima P1 version 2', tag_group: group },
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
    })
    await wrapper.setData({ tagSetId: null })
    expect(wrapper.vm.tag1Group.tags).toEqual([])
  })

  it('keeps configured names visible while looking up their tag data', async () => {
    const wrapper = makeWrapper({ tagSets: ['Ultima P2', 'Ultima P1 v2'] })
    expect(wrapper.findComponent({ name: 'TagSetsLookup' }).props('filter')).toEqual({
      tag_group_adapter_type_name: 'Ultima',
    })
    expect(wrapper.vm.tagSetOptions).toEqual([
      { value: null, text: 'Please select a Tagset...' },
      { value: 'Ultima P2', text: 'Ultima P2' },
      { value: 'Ultima P1 v2', text: 'Ultima P1 v2' },
    ])
    await wrapper.find('#ultima_tag_set').setValue('Ultima P1 v2')
    expect(wrapper.vm.tagSetId).toBe('Ultima P1 v2')
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0]).toMatchObject({
      tag1Group: { uuid: null, tags: [] },
      tag2Group: { uuid: null, tags: [] },
    })
    expect(wrapper.find('dl').exists()).toBe(false)
    await wrapper.setProps({ tagSets: [] })
    expect(wrapper.vm.coreTagSetOptions).toEqual([])
    await wrapper.setProps({ tagSets: ['Missing tag set'] })
    expect(wrapper.vm.coreTagSetOptions).toEqual([{ value: 'Missing tag set', text: 'Missing tag set' }])
  })

  it('resolves a configured selection when lookup results arrive and emits both tag groups', async () => {
    const wrapper = makeWrapper({ tagSets: ['Ultima P1 v2', 'Missing tag set'] })
    await wrapper.find('#ultima_tag_set').setValue('Ultima P1 v2')
    const tagGroup = { uuid: 'p1-v2', name: 'P1 v2', tags: [{ index: 1, oligo: 'ACGT' }] }
    const tag2Group = { uuid: 'p2', name: 'P2', tags: [{ index: 1, oligo: 'TGCA' }] }
    wrapper.findComponent({ name: 'TagSetsLookup' }).vm.$emit('change', {
      state: 'valid',
      results: {
        first: { id: 'first', name: 'Ultima P1 v1', tag_group: { ...tagGroup, uuid: 'p1-v1' } },
        second: { id: 'second', name: 'Ultima P1 v2', tag_group: tagGroup, tag2_group: tag2Group },
      },
    })
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0]).toMatchObject({
      tag1Group: tagGroup,
      tag2Group: tag2Group,
      walkingBy: 'manual by plate',
    })
    expect(wrapper.vm.coreTagSetOptions).toEqual([
      { value: 'Ultima P1 v2', text: 'Ultima P1 v2' },
      { value: 'Missing tag set', text: 'Missing tag set' },
    ])
    await wrapper.find('#ultima_tag_set').setValue('Missing tag set')
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0].tag1Group.tags).toEqual([])
    await wrapper.find('#ultima_tag_set').setValue('Ultima P1 v2')
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0].tag1Group).toEqual(tagGroup)
    wrapper.findComponent({ name: 'TagSetsLookup' }).vm.$emit('change', { state: 'invalid' })
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0].tag1Group.tags).toEqual([])
  })
})
