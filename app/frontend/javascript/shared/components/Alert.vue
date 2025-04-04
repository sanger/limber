<template>
  <div :class="['alert', `alert-${level}`, 'alert-dismissible', 'show']" role="alert">
    <strong>{{ title }}:</strong> {{ message }}
    <button type="button" class="btn-close" aria-label="Close" @click="$emit('close')">
      <span aria-hidden="true">&times;</span>
    </button>
  </div>
</template>

<script>
export default {
  name: 'LbAlert',
  props: {
    level: { type: String, default: 'info' },
    title: { type: String, default: '' },
    message: { type: String, default: '' },
  },
  emits: ['close'],
}
</script>
