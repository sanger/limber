
// Rotates through the available tags at a 1 second interval
const animateTags = (aliquot) => {
  // Take the first child, and move it to the back of the queue
  aliquot.appendChild( aliquot.children[0] )
  // Wait one second, then repeat
  window.setTimeout(animateTags, 1000, aliquot)
}

// Once the document has loaded
document.addEventListener('DOMContentLoaded', ()=>{

  const plate = document.getElementById('plate')

  if (plate && plate.dataset.animateTags) {
    // FInd all the aliquots in the plate
    const aliquots = plate.getElementsByClassName('aliquot')
    
    // Walk over each one
    for (let aliquotIndex = 0; aliquotIndex < aliquots.length; aliquotIndex++) {
      // Ignoring those with only one tag
      if (aliquots[aliquotIndex].children.length < 2) { return }
      // and set up the tag animation
      animateTags(aliquots[aliquotIndex])
    }
  }
}, false)


