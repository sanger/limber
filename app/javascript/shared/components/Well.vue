<template>
  <div :id="'well_' + position" :class="['well', position]">
    <div v-if="pool_index" :id="'aliquot_' + position" :class="['aliquot', colourClass]">
      <span :class="[linethroughClass, 'tag']" @click="onWellClicked">{{ tagMapIdDisplay() }}</span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Well',
  props: {
    position: { type: String, default: null },
    pool_index: { type: Number, default: null },
    tagMapIds: {
      type: Array,
      default: () => {
        return []
      },
    },
    validity: {
      type: Object,
      default: () => {
        return { valid: true, message: '' }
      },
    },
  },
  data() {
    return {
      tagIndex: 0,
    }
  },
  computed: {
    colourClass() {
      return this.validity.valid ? `colour-${this.pool_index}` : 'failed'
    },
    linethroughClass() {
      return this.validity.valid ? '' : 'line-through'
    },
  },
  created: function () {
    setInterval(this.updateTag, 1000)
  },
  methods: {
    onWellClicked() {
      this.$emit('onwellclicked', this.position)
    },
    tagMapIdDisplay() {
      if (this.tagMapIds.length === 0) {
        return ''
      } else {
        const tagMapId = this.tagMapIds[this.tagIndex]
        return tagMapId === -1 ? 'x' : tagMapId
      }
    },
    updateTag() {
      // We modulo this to ensure it goes 0,1,2,3,0,1,2,3
      if (this.tagMapIds.length === 0) {
        this.tagIndex = 0
      } else {
        this.tagIndex = (this.tagIndex + 1) % this.tagMapIds.length
      }
    },
  },
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
