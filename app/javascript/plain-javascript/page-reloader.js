console.log('Imported')
document.addEventListener('DOMContentLoaded', () => {
  console.log('Loaded')
  const timerElement = document.querySelector('[data-reload-time]')
  if (timerElement) {
    let timer = parseInt(timerElement.dataset['reloadTime'], 10)
    let interval = window.setInterval(_ => {
      timer -= 1 // Decrement timer
      timerElement.textContent = timer // Update the onscreen counter
      if (timer <= 0) { // If we've hit zero
        window.clearInterval(interval) // Stop the interval
        location.reload() // And reload the page
      }
    }, 1000)
  }
})
