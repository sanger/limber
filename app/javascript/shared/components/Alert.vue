<template>
  <div :class="['alert', `alert-${level}`, 'alert-dismissible', 'show']" role="alert">
    <strong>{{ title }}:</strong> {{ message }}
    <button type="button" class="close" @click="$emit('close')" aria-label="Close">
      <span aria-hidden="true">&times;</span>
    </button>
  </div>
</template>

<script>
export default {
  name: 'Alert',
  props: {
    level: { type: String, default: 'info' },
    title: { type: String, default: '' },
    message: { type: String, default: '' },
  },
}
</script>
