// Behaves similarly to Array.from(length, function(_, iteration))
const buildArray = function(length, constructor) {
  var array = new Array(length)
  for (let i = 0; i < length; i++) {
    array[i] = constructor(i)
  }
  return array
}

export default buildArray
