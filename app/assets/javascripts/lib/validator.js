var validator = function(validation, message) {
  this.validation = validation;
  this.message = message;
};

validator.prototype = {
  validate: function(target) {
    if (this.validation(target)) {
      return { valid: true, message: 'is valid' };
    } else {
      return { valid: false, message: this.message };
    }
  }
};
