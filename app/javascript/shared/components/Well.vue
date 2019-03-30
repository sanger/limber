<template>
  <div
    :class="['well', position]"
    :id="'well_' + position"
  >
    <div
      v-if="pool_index"
      :id="'aliquot_' + position"
      :class="['aliquot', colourClass ]"
    >
      <span
        v-for="(tagMapId, index) in tagMapIds"
        :key="'tag_' + index"
        :class="[linethroughClass, 'tag']"
        @click="onWellClicked"
      >{{ tagMapIdDisplay(tagMapId) }}</span>
    </div>
  </div>
</template>

<script>

export default {
  name: 'Well',
  props: {
    position: { type: String, default: null },
    pool_index: { type: Number, default: null },
    tagMapIds: { type: Array, default: () => { return [] } },
    validity: { type: Object, default: () => { return { valid: true, message: '' }} }
  },
  computed: {
    colourClass() {
      return ((this.validity.valid) ? `colour-${this.pool_index}` : 'failed' )
    },
    linethroughClass() {
      return ((this.validity.valid) ? '' : 'line-through' )
    }
  },
  methods: {
    onWellClicked() {
      this.$emit('onwellclicked', this.position )
    },
    tagMapIdDisplay(tagMapId) {
      return (tagMapId === -1) ? 'x' : tagMapId
    }
  }
}
</script>

<style scoped>
  .line-through {
    text-decoration: line-through;
  }

  .tag {
    display: none;
  }

  .tag:first-child {
    display: inline;
  }
</style>