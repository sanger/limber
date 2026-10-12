import { mount, shallowMount } from '@vue/test-utils'
import ManualUltimaTagLayout from './ManualUltimaTagLayout.vue'
import ManualUltimaTaggedPlate from './ManualUltimaTaggedPlate.vue'

describe('ManualUltimaTaggedPlate tag set configuration', () => {
  it('decodes the page configuration and passes it to the manual controls', () => {
    const wrapper = shallowMount(ManualUltimaTaggedPlate, {
      props: { tagSets: JSON.stringify(['Ultima P1', 'Ultima P2']) },
      global: {
        stubs: {
          CustomTaggedPlate: {
            template:
              '<slot name="tag-layout-controls" :api="{}" :number-of-tags="0" :number-of-target-wells="0" :tags-per-well="1" />',
          },
        },
      },
    })
    expect(wrapper.findComponent(ManualUltimaTagLayout).props('tagSets')).toEqual(['Ultima P1', 'Ultima P2'])
  })
})
