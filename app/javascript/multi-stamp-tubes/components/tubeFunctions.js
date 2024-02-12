/* Given a list of items and an element, reduce the list to a unique set of items, and return the new idex of the provided element.
 * @param {Array} items - The list of items to reduce.
 * @param {Object} element - The element to find the unique index of.
 * @returns {Number} - The unique index of the provided index.
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 0) => -1
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 1) => 0
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 2) => 1
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 3) => 2
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 4) => -1
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 5) => 3
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 6) => -1
 */
const findUniqueIndex = (items, element) => {
  const uniqueItems = [...new Set(items)]
  return uniqueItems.indexOf(element)
}

export { findUniqueIndex }
