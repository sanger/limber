# frozen_string_literal: true

module Forms
  class PoolingRowToColumn < CreationForm
    include Forms::Form::NoCustomPage

    self.default_transfer_template_uuid = Settings.transfer_templates['Pooling rows to first column']
  end
end
