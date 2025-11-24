import SCAPE from '@/javascript/lib/global_message_system'

let sendDuplicateTagsWarning = function (plates) {
  if (plates.length <= 1) return

  const lastScannedPlateIndex = plates.length - 1
  const lastScannedPlate = plates[lastScannedPlateIndex]

  const lastTagGroupsMap = new Map(lastScannedPlate.tagGroupsList.map((tg) => [tg.id, tg]))

  const warningMessages = []

  for (let i = 0; i < lastScannedPlateIndex; i++) {
    const duplicateTags = plates[i].tagGroupsList.filter((tg) => lastTagGroupsMap.has(tg.id))

    if (duplicateTags.length > 0) {
      const duplicateNames = duplicateTags.map((tg) => tg.name).join(', ')
      warningMessages.push(
        `Plate ${lastScannedPlate.humanBarcode} and Plate ${plates[i].humanBarcode} share the same tag group(s): ${duplicateNames}.`,
      )
    }
  }

  if (warningMessages.length > 0) {
    SCAPE.message(`Warning: ${warningMessages.join('\n')}`, 'warning')
  }
}


export { sendDuplicateTagsWarning }