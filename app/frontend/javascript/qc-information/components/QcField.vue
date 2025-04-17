<template>
  <b-form-group :label="titleize(name)">
    <b-row>
      <b-col>
        <b-form-group label="Value" :label-for="`qc-field-${name}-value`" label-visually-hidden>
          <b-input-group :append="units">
            <b-form-input
              :id="`qc-field-${name}-value`"
              v-model="value"
              :type="dataType"
              v-bind="fieldOptions"
              @change="emitOnChange"
            />
          </b-input-group>
        </b-form-group>
      </b-col>
      <b-col>
        <b-form-group label="Assay Type" :label-for="`qc-field-${name}-assay-type`" label-visually-hidden>
          <b-form-select
            :id="`qc-field-${name}-assay-type`"
            v-model="assayType"
            :options="assayTypes"
            @change="emitOnChange"
          />
        </b-form-group>
      </b-col>
    </b-row>
  </b-form-group>
</template>

<script>
export default {
  name: 'QcField',
  props: {
    name: { type: String, required: true },
    units: { type: String, required: true },
    defaultValue: { type: String, required: false, default: null },
    defaultAssayType: { type: String, required: false, default: 'Estimated' },
    dataType: { type: String, default: 'number' },
    assayTypes: {
      type: Array,
      default: () => {
        return ['Estimated']
      },
    },
    fieldOptions: {
      type: Object,
      default: () => {
        return { step: 0.01, min: 0 }
      },
    },
    assetUuid: { type: String, required: true },
  },
  emits: ['change'],
  data() {
    return {
      value: this.defaultValue,
      assayType: this.defaultAssayType,
    }
  },
  methods: {
    emitOnChange(_value) {
      this.$emit('change', {
        value: this.value,
        assay_type: this.assayType,
        units: this.units,
        key: this.name,
        assay_version: 'manual',
        uuid: this.assetUuid,
      })
    },
    titleize(name) {
      if (!name) return ''
      name = name.toString().replace('_', ' ')
      return name.charAt(0).toUpperCase() + name.slice(1)
    },
  },
}
</script>
