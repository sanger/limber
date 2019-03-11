<template>
  <div class="list-group">
    <div
      v-if="loading"
      class="spinner-dark"
    >
      Updating...
    </div>
    <a
      v-for="qc_file in qc_files"
      class="list-group-item"
      :href="'/qc_files/' + qc_file.uuid"
    >
      {{ qc_file.filename }} - {{ qc_file.created }}
    </a>
    <div
      v-if="noFiles"
      class="list-group-item"
    >
      No files attached
    </div>
  </div>
</template>

<script>

export default {
  name: 'FileList',
  data () {
    return {
      base_url: window.location.pathname + '/qc_files',
      qc_files: [],
      loading: true
    }
  },
  computed: {
    noFiles() { return this.qc_files && this.qc_files.length === 0 && !this.loading }
  },
  methods: {
    fetchData: function () {
      var self = this
      self.loading = true
      var xhr = new XMLHttpRequest()
      xhr.open('GET', self.base_url)
      xhr.onload = function () {
        self.qc_files = JSON.parse(xhr.responseText)['qc_files']
        self.loading = false
      }
      xhr.send()
    }
  }
}
</script>
