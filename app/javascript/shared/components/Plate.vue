<!-- Encapsulates the main page content
     Can have two children:
      - MainContent: The LHS, what you HAVE
      - Sidebar: The RHS, what you can do
-->
<template>
  <table v-bind:class="['plate-view', sizeClass]">
    <caption>{{ caption }}</caption>
    <thead>
      <tr>
        <th class="first-col"></th>
        <th v-for="column in columns">{{ column }}</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="row in rows">
        <th class="first-col">{{ row | toLetter }}</th>
        <td v-for="column in columns"><div class="well"></div></td>
      </tr>
    </tbody>
  </table>
</template>

<script>
  export default {
    name: 'Page',
    props: {
      columns: { type: Number, default: 12 },
      rows: { type: Number, default: 8 },
      caption: { type: String }
    },
    computed: {
      sizeClass: function () { return 'plate-' + (this.columns * this.rows) }
    },
    filters: {
      toLetter: function (value) {
        return String.fromCharCode(value + 64)
      }
    }
  }
</script>
