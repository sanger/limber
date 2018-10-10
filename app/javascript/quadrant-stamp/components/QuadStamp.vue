<template>
  <lb-page>
    <lb-main-content>
      <div class="alert alert-info">
        <h2>Debug properties:</h2>
        {{ _props }}
      </div>
      <b-card bg-variant="dark" text-variant="white">
          {{ sequencescapeApi }}
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card header="Add plates" header-tag="h3">
        <p class="card-text">Scan in the plates you wish to use.</p>
      </b-card>
    </lb-sidebar>
  </lb-page>
</template>

<script>

export default {
  name: 'QuadStamp',
  data () {
    return {}
  },
  props: {
    sequencescapeApi: { type: String, default: 'Happy Sausages' }
  },
  methods: {}
}
</script>
