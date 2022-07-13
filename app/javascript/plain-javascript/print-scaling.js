/*
 * Monitors the page and detects and transitions to and from landscape printing.
 * Upon transition to landscape printing, detects the size of the plate relative
 * to the document (ie. the page width) and scales it to fit.
 * Will revert any scaling when switching out of landscape-printing
 */
window.matchMedia('print and (orientation: landscape)').addEventListener('change', ({ matches }) => {
  const plateElement = document.getElementById('plate')
  if (matches) {
    const plateWidth = plateElement.offsetWidth
    const printWidth = document.body.offsetWidth
    const scaleFactor = printWidth / plateWidth
    plateElement.style.transform = `scale(${scaleFactor})`
  } else {
    plateElement.style.transform = 'scale(1)'
  }
})
