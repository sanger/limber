module Forms
  class PoolingRowToColumn < CreationForm
    include Forms::Form::NoCustomPage

    write_inheritable_attribute :default_transfer_template_uuid, Settings.transfer_templates['Pooling rows to first column']
  end
end
