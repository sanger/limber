// Simple incrementing counter, starting from 1
export default (initial) => {
  let value = initial - 1 || 0
  return () => { return value += 1 }
}
