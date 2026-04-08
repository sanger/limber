<template>
  <div>
    <b-container>
      <b-row style="margin-bottom: 10px">
        <b>Scan the pair of tubes to be blended:</b>
      </b-row>
      <b-row>
        <b-col>
          <lb-labware-scan
            :key="0"
            :api="api"
            :label="'Tube 1'"
            :includes="tubeIncludes"
            :fields="tubeFields"
            :validators="scanValidation"
            :labware-type="'tube'"
            :valid-message="''"
            @change="updateTube(0, $event)"
          />
        </b-col>
      </b-row>
      <b-row>
        <b-col>
          <lb-labware-scan
            :key="1"
            :api="api"
            :label="'Tube 2'"
            :includes="tubeIncludes"
            :fields="tubeFields"
            :validators="scanValidation"
            :labware-type="'tube'"
            :valid-message="''"
            @change="updateTube(1, $event)"
          />
        </b-col>
      </b-row>
    </b-container>
    <b-container style="margin-bottom: 20px">
      <b-row>
        <div
          :style="{
            backgroundColor: colorForState,
            width: '50px',
            height: '30px',
            borderRadius: '5px',
            marginRight: '10px',
          }"
        ></div>
        <div id="pairing_state_message">
          <span :class="stateMessageClass">{{ stateMessage }}</span>
        </div>
      </b-row>
    </b-container>
    <b-card bg-variant="white" text-variant="black" :header="'Summary for this pairing:'" header-tag="h5">
      <label>Scanned tubes:</label>
      <ul>
        <li v-for="(tube, index) in pairedTubes" :key="index">
          Tube {{ index + 1 }}:
          <b>{{
            tube.labware
              ? tube.labware.labware_barcode.human_barcode +
                ' (' +
                tube.labware.labware_barcode.machine_barcode +
                ') - ' +
                tube.labware.purpose.name
              : 'No tube scanned'
          }}</b>
        </li>
      </ul>
      <div v-if="validatedTubes">
        <p>
          Matching Ancestor:
          <b>{{
            sharedAncestorPlate
              ? sharedAncestorPlate.labware_barcode.human_barcode + ' - ' + sharedAncestorPlate.purpose.name
              : 'No shared ancestor'
          }}</b>
        </p>
        <p>
          Sufficient samples match: <b>{{ tubesHaveMatchingSamples ? 'Yes' : 'No' }}, {{ matchedSamplesSummary }}</b>
        </p>
        <div v-if="haveNonMatchedSamples">
          Non-matching samples:
          <ul>
            <li v-for="(sample, index) in nonMatchingSamples" :key="index">
              <b>{{ sample.name }}</b>
              <span v-if="sample.inTube1"> in Tube 1</span>
              <span v-else> missing from Tube 1</span>
              <span v-if="sample.inTube2">, in Tube 2</span>
              <span v-else>, missing from Tube 2</span>
            </li>
          </ul>
        </div>
      </div>
    </b-card>
  </div>
</template>

<script>
import LabwareScan from '@/javascript/shared/components/LabwareScan.vue'
import {
  checkAcceptablePurposes,
  checkState,
  checkDuplicates,
} from '@/javascript/shared/components/tubeScanValidators.js'
// import { validScanMessage } from '@/javascript/shared/components/scanValidators.js'
import filterProps from './filterProps.js'
import { buildTubeObjs } from '@/javascript/shared/tubeHelpers.js'
/**
 * PairTubesToBlend provides:
 * - Allows user to scan a pair of tubes to be blended.
 * - Emits a pair of tube objects, along with their validity.
 */
export default {
  name: 'PairTubesToBlend',
  components: {
    'lb-labware-scan': LabwareScan,
  },
  props: {
    // list of acceptable parent tube purposes
    acceptableParentTubePurposesArray: {
      type: Array,
      default: () => [],
    },
    // the name of the parent tube purpose that will always have a single ancestor plate
    singleAncestorParentTubePurpose: {
      type: String,
      default: '',
    },
    api: {
      // A devour API object. eg. new devourClient(apiOptions)
      // In practice you probably want to use the helper in shared/devourApi
      type: Object,
      required: true,
    },
    labwareType: {
      type: String,
      default: 'tube',
    },
    // The ancestor plate purpose name which comes from the purpose config
    ancestorLabwarePurposeName: {
      type: String,
      required: true,
    },
  },
  emits: ['change'],
  data() {
    return {
      pairedTubes: buildTubeObjs(2),
      errorMessages: [],
      state: 'empty',
    }
  },
  computed: {
    tubeIncludes() {
      return filterProps.tubeIncludes
    },
    tubeFields() {
      return filterProps.tubeFields
    },
    // checks run on the tube scanned
    scanValidation() {
      const validators = []

      // If any acceptableParentTubePurposes specified then ensure we validate against them
      if (this.acceptableParentTubePurposesArray.length) {
        validators.push(checkAcceptablePurposes(this.acceptableParentTubePurposesArray))
      }

      // Check the state of the parent tubes is passed
      validators.push(checkState(['passed']))

      // check the tubes scanned are not the same (duplicates)
      const currTubes = this.pairedTubes.map((tubeItem) => tubeItem.labware)
      validators.push(checkDuplicates(currTubes))

      return validators
    },
    colorForState() {
      if (this.state === 'empty') {
        return 'grey'
      } else if (this.state === 'warning') {
        return 'orange'
      } else if (this.state === 'invalid') {
        return 'red'
      } else if (this.state === 'valid') {
        return 'green'
      } else {
        return 'gray' // default color
      }
    },
    stateMessage() {
      if (this.state === 'empty') {
        return 'Awaiting tube scans...'
      } else if (this.state === 'warning') {
        return 'Scan the other tube...'
      } else if (this.state === 'invalid') {
        return 'Invalid: ' + this.formattedErrorMessages()
      } else if (this.state === 'valid') {
        return 'Valid Pairing!'
      } else {
        return 'Unknown state...' // default
      }
    },
    stateMessageClass() {
      if (this.state === 'empty') {
        return 'color-black'
      } else if (this.state === 'warning') {
        return 'color-orange'
      } else if (this.state === 'invalid') {
        return 'color-red'
      } else if (this.state === 'valid') {
        return 'color-green'
      } else {
        return 'color-black' // default color class
      }
    },
    areTubeScansEmpty() {
      return this.pairedTubes.every((tube) => tube.labware === null)
    },
    areBothTubesScanned() {
      return this.pairedTubes.length === 2 && this.pairedTubes.every((tube) => tube && tube.labware !== null)
    },
    areBothTubesValid() {
      return this.pairedTubes.every((tube) => tube.state === 'valid')
    },
    sharedAncestorPlate() {
      if (!this.validatedTubes()) {
        return null
      }

      const sharedAncestor = this.findSharedAncestor()

      if (sharedAncestor) {
        return sharedAncestor
      } else {
        return null
      }
    },
    tubesHaveMatchingSamples() {
      if (!this.validatedTubes()) {
        return false
      }

      const tubeSampleIds = this.pairedTubes.map((tube) => this.extractSampleIds(tube))

      // Ensure there are two tubes with sample IDs
      if (tubeSampleIds.length !== 2) {
        return false
      }

      const [tube1SampleIds, tube2SampleIds] = tubeSampleIds

      // Check if there is at least one common sample ID
      const hasAtLeastOneSharedSample = tube1SampleIds.some((id) => tube2SampleIds.includes(id))

      return hasAtLeastOneSharedSample
    },
    matchedSamplesSummary() {
      if (!this.validatedTubes()) {
        return 'valid pairing required first'
      }

      const tubeSampleIds = this.pairedTubes.map((tube) => this.extractSampleIds(tube))

      // Ensure there are two tubes with sample IDs
      if (tubeSampleIds.length !== 2) {
        return 'valid pairing required first'
      }

      const [tube1SampleIds, tube2SampleIds] = tubeSampleIds

      // Find matching sample IDs
      const matchedSampleIds = tube1SampleIds.filter((id) => tube2SampleIds.includes(id))
      const totalSamples = new Set([...tube1SampleIds, ...tube2SampleIds]).size

      // Return the summary
      return `${matchedSampleIds.length} of ${totalSamples} samples match`
    },
    nonMatchingSamples() {
      if (!this.validatedTubes()) {
        return []
      }

      const tubeSampleIds = this.pairedTubes.map((tube) => this.extractSampleIds(tube))
      const tubeSampleNames = this.pairedTubes.map(
        (tube) => tube.labware?.receptacle?.aliquots.map((aliquot) => aliquot.sample.name) || [],
      )

      // Ensure there are two tubes with sample IDs
      if (tubeSampleIds.length !== 2) {
        return []
      }

      const [tube1SampleIds, tube2SampleIds] = tubeSampleIds
      const [tube1SampleNames, tube2SampleNames] = tubeSampleNames

      const nonMatchingSamples = []

      // Find samples in tube 1 that are not in tube 2
      tube1SampleIds.forEach((id, index) => {
        if (!tube2SampleIds.includes(id)) {
          nonMatchingSamples.push({
            name: tube1SampleNames[index],
            inTube1: true,
            inTube2: false,
          })
        }
      })

      // Find samples in tube 2 that are not in tube 1
      tube2SampleIds.forEach((id, index) => {
        if (!tube1SampleIds.includes(id)) {
          nonMatchingSamples.push({
            name: tube2SampleNames[index],
            inTube1: false,
            inTube2: true,
          })
        }
      })

      return nonMatchingSamples
    },
    haveNonMatchedSamples() {
      return this.nonMatchingSamples.length > 0
    },
  },
  watch: {
    pairedTubes: {
      handler() {
        this.performPairingValidations() // Trigger the method
      },
      deep: true, // Ensures nested changes are detected
    },
    state() {
      let message = {
        pairedTubes: this.pairedTubes,
        state: this.state,
      }

      this.$emit('change', message)
    },
  },
  methods: {
    updateTube(index, data) {
      this.pairedTubes[index] = { ...data, index: index }
    },
    performPairingValidations() {
      this.errorMessages = []
      // skip validation if no tubes have been scanned
      if (this.areTubeScansEmpty) {
        this.state = 'empty'
        return
      }

      // check pairedTubes contains 2 tubes
      if (!this.areBothTubesScanned) {
        this.state = 'warning'
        return
      }

      // check pairedTubes are both valid
      if (this.pairedTubes.some((tube) => tube.state == 'invalid')) {
        this.state = 'invalid'
        this.errorMessages.push('One or more tube is invalid')
        return
      }

      // check pairedTubes have the same ancestor
      if (!this.sharedAncestorPlate) {
        this.state = 'invalid'
        this.errorMessages.push('The tubes do not share a common ancestor')
        return
      }

      // check pairedTubes have the same samples
      if (!this.tubesHaveMatchingSamples) {
        this.state = 'invalid'
        this.errorMessages.push('The tubes do not share any of the same samples')
        return
      }

      this.state = 'valid'

      return
    },
    findAncestors() {
      const tubeAncestors = this.pairedTubes.map((tube) => {
        // Ensure ancestors exist
        if (!tube.labware.ancestors || tube.labware.ancestors.length === 0) {
          this.errorMessages.push(
            `Tube with purpose: "${tube.labware.purpose.name}" does not appear to have any ancestors. Cannot confirm if safe to blend.`,
          )
          return []
        }

        // determine filtered ancestors for this tube
        const filteredAncestors = tube.labware.ancestors.filter(
          (ancestor) => ancestor.purpose.name === this.ancestorLabwarePurposeName,
        )

        // if there are no filtered ancestors, return an empty array
        if (filteredAncestors.length === 0) {
          this.errorMessages.push(
            `Tube with purpose: "${this.singleAncestorParentTubePurpose}"  did not have the expected ancestor plate of purpose: "${this.ancestorLabwarePurposeName}".`,
          )
          return []
        }

        // If the tube's purpose matches singleAncestorParentTubePurpose, ensure it has only one ancestor
        if (tube.labware.purpose.name === this.singleAncestorParentTubePurpose) {
          if (filteredAncestors.length !== 1) {
            const ancestorBarcodes = filteredAncestors.map((ancestor) => ancestor.labware_barcode.human_barcode)
            this.errorMessages.push(
              `Tube with purpose: "${this.singleAncestorParentTubePurpose}" must have exactly one ancestor plate of purpose: "${this.ancestorLabwarePurposeName}". Found: ${ancestorBarcodes.join(', ')}`,
            )
            return [] // Return an empty array if the condition is not met
          }
        }

        return filteredAncestors
      })

      return tubeAncestors
    },
    formattedErrorMessages() {
      return this.errorMessages.join(', ')
    },
    extractSampleIds(tube) {
      if (!tube.labware || !tube.labware.receptacle || !tube.labware.receptacle.aliquots) {
        return []
      }

      // Extract sample IDs from aliquots
      const sampleIds = tube.labware.receptacle.aliquots.map((aliquot) => aliquot.sample.id)
      return sampleIds
    },
    validatedTubes() {
      return this.areBothTubesScanned && this.areBothTubesValid
    },
    findSharedAncestor() {
      const tubeAncestors = this.findAncestors()

      // Ensure there are exactly two tubes with ancestors
      if (tubeAncestors.length !== 2) {
        return null
      }

      // Check if any of the ancestor arrays is empty
      if (tubeAncestors.some((ancestors) => ancestors.length === 0)) {
        return null
      }

      const tubeWithSingleAncestor = this.pairedTubes.find(
        (tube) => tube.labware && tube.labware.purpose.name === this.singleAncestorParentTubePurpose,
      )

      if (!tubeWithSingleAncestor || !tubeWithSingleAncestor.labware.ancestors) {
        return null
      }

      // Find the ancestor matching the expected purpose
      const ancestorLabware = tubeWithSingleAncestor.labware.ancestors.find(
        (ancestor) => ancestor.purpose.name === this.ancestorLabwarePurposeName,
      )

      if (!ancestorLabware) {
        return null
      }

      // Check if the other tube in the pair has the same ancestor
      const otherTubeAncestors = this.pairedTubes
        .filter((tube) => tube !== tubeWithSingleAncestor)
        .flatMap((tube) => tube.labware.ancestors)

      return otherTubeAncestors.find((ancestor) => ancestor.id === ancestorLabware.id) || null
    },
  },
}
</script>

<style scoped lang="scss">
.color-black {
  color: black;
}
.color-orange {
  color: orange;
}
.color-red {
  color: red;
}
.color-green {
  color: green;
}
</style>
