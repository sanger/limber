import $ from 'jquery'
import SCAPE from '@/javascript/lib/global_message_system.js'

describe('bed_verification plate scan handler', () => {
  let plateScan, bedScan, robotScan

  // NB. use of beforeAll is not ideal but could not get beforeEach to work.
  // Deemed acceptable in this case as the two tests could mimic a sequence that could happen in
  // real life.
  beforeAll(async () => {
    // Set up DOM elements
    document.body.innerHTML = `
			<input id="plate_scan" />
			<input id="bed_scan" />
			<input id="robot_scan" />
		`
    plateScan = $('#plate_scan')
    bedScan = $('#bed_scan')
    robotScan = $('#robot_scan')

    // Mock SCAPE.message
    SCAPE.message = vi.fn()

    // Import and attach the handler
    await import('./bed_verification.js')
  })

  it('shows warning and does not scan plate if bed_scan is empty', () => {
    bedScan.val('')
    plateScan.val('PLATE123')
    plateScan.trigger('change')

    // We expect a message on screen requesting user scan the bed first
    expect(SCAPE.message).toHaveBeenCalledWith('Scan the bed before the plate please!', 'warning')
  })

  it('clears warning and scans plate if bed_scan has value', () => {
    robotScan.val('ROBOT123')
    bedScan.val('BED123')
    plateScan.val('PLATE123')
    plateScan.trigger('change')

    // We clear the message field if we have a bed barcode, so we expect an empty message to be sent
    expect(SCAPE.message).toHaveBeenCalledWith('', '')
  })
})
