import { mount } from '@vue/test-utils'
import FileList from './FileList.vue'

describe('FileList.vue', () => {
  let wrapper

  beforeEach(() => {
    wrapper = mount(FileList, {
      data() {
        return {
          qc_files: [],
          loading: true,
        }
      },
    })
  })

  it('renders loading spinner when loading is true', () => {
    expect(wrapper.find('.spinner-dark').exists()).toBe(true)
  })

  it('does not render loading spinner when loading is false', async () => {
    await wrapper.setData({ loading: false })
    expect(wrapper.find('.spinner-dark').exists()).toBe(false)
  })

  it('renders "No files attached" when noFiles is true', async () => {
    await wrapper.setData({ loading: false, qc_files: [] })
    expect(wrapper.find('.list-group-item').text()).toBe('No files attached')
  })

  it('renders qc_files when they are present', async () => {
    const mockFiles = [
      { uuid: '1', filename: 'file1.txt', created: '2023-01-01' },
      { uuid: '2', filename: 'file2.txt', created: '2023-01-02' },
    ]
    await wrapper.setData({ loading: false, qc_files: mockFiles })
    const fileLinks = wrapper.findAll('.list-group-item')
    expect(fileLinks.length).toBe(2)
    expect(fileLinks.at(0).text()).toBe('file1.txt - 2023-01-01')
    expect(fileLinks.at(1).text()).toBe('file2.txt - 2023-01-02')
  })

  it('computed noFiles returns true when qc_files is empty and loading is false', async () => {
    await wrapper.setData({ loading: false, qc_files: [] })
    expect(wrapper.vm.noFiles).toBe(true)
  })

  it('computed noFiles returns false when qc_files is not empty', async () => {
    await wrapper.setData({ loading: false, qc_files: [{ uuid: '1', filename: 'file1.txt', created: '2023-01-01' }] })
    expect(wrapper.vm.noFiles).toBe(false)
  })

  it('calls fetchData on mount', () => {
    const fetchDataSpy = vi.spyOn(FileList.methods, 'fetchData')
    mount(FileList)
    expect(fetchDataSpy).toHaveBeenCalled()
  })
})
