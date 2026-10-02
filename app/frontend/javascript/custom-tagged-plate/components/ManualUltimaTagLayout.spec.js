import { mount } from '@vue/test-utils'
import ManualUltimaTagLayout from './ManualUltimaTagLayout.vue'

describe('ManualUltimaTagLayout', () => {
  const makeWrapper = () =>
    mount(ManualUltimaTagLayout, {
      props: { api: {} },
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
})
