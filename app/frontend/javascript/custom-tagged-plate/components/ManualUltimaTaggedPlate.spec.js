import { shallowMount } from '@vue/test-utils'
import ManualUltimaTagLayout from './ManualUltimaTagLayout.vue'
import ManualUltimaTaggedPlate from './ManualUltimaTaggedPlate.vue'

describe('ManualUltimaTaggedPlate tag set configuration', () => {
  const applications = [
    {
      name: '10x Flex v2',
      uga_primer: 'UG-CE-tR1',
      ugb_primer: 'UG-srR2',
    },
  ]

  it.each([{ names: ['Ultima P1', 'Ultima P2'] }, { names: null }, { names: [] }])(
    'passes allowed tag set names $names to the manual controls',
    ({ names }) => {
      const wrapper = shallowMount(ManualUltimaTaggedPlate, {
        props: {
          allowedTagSetNames: JSON.stringify(names),
          ultimaApplications: JSON.stringify(applications),
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
      const controls = wrapper.findComponent(ManualUltimaTagLayout)
      expect(controls.props('allowedTagSetNames')).toEqual(names)
      expect(controls.props('ultimaApplications')).toEqual(applications)
    },
  )
})
