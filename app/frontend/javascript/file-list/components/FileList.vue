<template>
  <div class="list-group list-group-flush"  @click="handleClick">
    <div v-if="loading" class="spinner-dark">Updating...</div>
    <a v-for="qc_file in qc_files" :key="qc_file.uuid" class="list-group-item" :href="'/qc_files/' + qc_file.uuid">
      {{ qc_file.filename }} - {{ qc_file.created }}
    </a>
    <div v-if="noFiles" class="list-group-item">No files attached</div>
  </div>
</template>

<script>
export default {
  name: 'FileList',
  data() {
    return {
      base_url: window.location.pathname + '/qc_files',
      qc_files: [],
      loading: true,
    }
  },
  computed: {
    noFiles() {
      return this.qc_files && this.qc_files.length === 0 && !this.loading
    },
  },
  methods: {
    fetchData: function () {
      let self = this
      self.loading = true
      let xhr = new XMLHttpRequest()
      xhr.open('GET', self.base_url)
      xhr.onload = function () {
        self.qc_files = JSON.parse(xhr.responseText)['qc_files']
        self.loading = false
      }
      xhr.send()
    },
    handleClick() {
      this.fetchData()
    }
  },
}
</script>
