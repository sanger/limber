<template>
  <b-form-group :label="name | titleize">
    <b-row>
      <b-col>
    <b-form-group
      label="Value"
      :label-for="`qc-field-${name}-value`"
      label-sr-only>
      <b-input-group :append="units">
        <b-form-input
          :id="`qc-field-${name}-value`"
          :type="dataType"
          v-bind="fieldOptions"
          v-model="value"
          @input="emitOnChange"/>
      </b-input-group>
    </b-form-group>
  </b-col>
  <b-col>
    <b-form-group label="Assay Type" :label-for="`qc-field-${name}-assay-type`" label-sr-only>
      <b-form-select
        :id="`qc-field-${name}-assay-type`"
        :options="assayTypes"
        v-model="assayType"
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
    data () {
      return {
        value: this.defaultValue,
        assayType: this.defaultAssayType
      }
    },
    props: {
      name: { type: String, required: true },
      units: { type: String, required: true },
      defaultValue: { type: String, required: false, default: null },
      defaultAssayType: { type: String, required: false, default: 'Estimated' },
      dataType: { type: String, default: 'number' },
      assayTypes: { type: Array, default: () =>{ return ['Estimated'] } },
      fieldOptions: { type: Object, default: () => { return { step: 0.01, min: 0 } }},
      assetUuid: { typw: String, required: true }
    },
    methods: {
      emitOnChange(_value) {
        this.$emit('change',  {
          value: this.value,
          assay_type: this.assayType,
          units: this.units,
          key: this.name,
          assay_version: 'manual',
          uuid: this.assetUuid
        })
      }
    },
    filters: {
      titleize(value) {
        if (!value) return ''
        value = value.toString().replace('_',' ')
        return value.charAt(0).toUpperCase() + value.slice(1)
      }
    }
  }
</script>
