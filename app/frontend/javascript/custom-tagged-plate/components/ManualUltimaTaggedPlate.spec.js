import { shallowMount } from '@vue/test-utils'
import ManualUltimaTagLayout from './ManualUltimaTagLayout.vue'
import ManualUltimaTaggedPlate from './ManualUltimaTaggedPlate.vue'

describe('ManualUltimaTaggedPlate tag set configuration', () => {
  it.each([{ names: ['Ultima P1', 'Ultima P2'] }, { names: null }, { names: [] }])(
    'passes allowed tag set names $names to the manual controls',
    ({ names }) => {
      const wrapper = shallowMount(ManualUltimaTaggedPlate, {
        props: {
          allowedTagSetNames: JSON.stringify(names),
          ultimaApplications: JSON.stringify(['Application A']),
        },
        global: {
          stubs: {
            CustomTaggedPlate: {
              template:
                '<slot name="tag-layout-controls" :api="{}" :number-of-tags="0" :number-of-target-wells="0" :tags-per-well="1" />',
            },
          },
        },
      })
      expect(wrapper.findComponent(ManualUltimaTagLayout).props('allowedTagSetNames')).toEqual(names)
      expect(wrapper.findComponent(ManualUltimaTagLayout).props('ultimaApplications')).toEqual(['Application A'])
    },
  )
})
