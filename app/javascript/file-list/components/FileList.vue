<template>
<div class="list-group">
<div class="spinner-dark" v-if="loading">Updating...</div>
<a class="list-group-item" v-for="qc_file in qc_files" v-bind:href="'/qc_files/' + qc_file.uuid">
  {{qc_file.filename}} - {{ qc_file.created }}
</a>
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
  methods: {
    fetchData: function () {
      var self = this;
      self.loading = true;
      var xhr = new XMLHttpRequest();
      xhr.open('GET', self.base_url);
      xhr.onload = function () {
        self.qc_files = JSON.parse(xhr.responseText)['qc_files']
        self.loading = false
      };
      xhr.send();
    }
  }
}
</script>
