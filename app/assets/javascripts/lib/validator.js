// accepts a `validation` function which returns true (valid) or false (invalid)
// and a `message` string for when it's invalid
var validator = function(validation, message) {
  this.validation = validation;
  this.message = message;
};

validator.prototype = {

  // returns an object with `valid` boolean
  // and a string message
  validate: function(target) {
    if (this.validation(target)) {
      return { valid: true, message: 'is valid' };
    } else {
      return { valid: false, message: this.message };
    }
  }
};
