# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.
module Presenters
  module Presenter
    def self.included(base)
      base.class_eval do
        include Forms::Form
        self.page = 'show'

        class_attribute :csv
        self.csv = 'show'

        def has_qc_data?
          false
        end
      end
    end

    def save!
    end

    def purpose_config
      Settings.purposes[purpose.uuid]
    end

    def default_printer_uuid
      @default_printer_uuid ||= Settings.printers[purpose_config.default_printer_type]
    end

    def default_label_count
      @default_label_count ||= Settings.printers['default_count']
    end

    def printer_limit
      @printer_limit ||= Settings.printers['limit']
    end

    def suitable_labware
      yield
    end

    def errors
      nil
    end

    def label_type
      yield 'custom-labels'
      nil
    end

    def prioritized_name(str, max_size)
      # Regular expression to match
      return 'Unnamed' if str.blank?
      match = str.match(/([A-Z]{2})(\d+)([[:alpha:]])( )(\w+)(:)(\w+)/)
      return str if match.nil?
      # Sets the priorities position matches in the regular expression to dump into the final string. They will be
      # performed with preference on the most right characters from the original match string
      priorities = [7, 5, 2, 6, 3, 1, 4]

      # Builds the final string by adding the matching string using the previous priorities list
      priorities.each_with_object([]) do |value, cad_list|
        size_to_copy = max_size - cad_list.join('').length
        text_to_copy = match[value]
        cad_list[value] = (text_to_copy[[0, text_to_copy.length - size_to_copy].max, size_to_copy])
        cad_list
      end.join('')
    end

    def statechange_link(_view)
      '#'
    end

    def if_statechange_active(content)
      content
    end

    def statechange_label
      default_statechange_label
    end

    def default_statechange_label
      'Move to next state'
    end

    def statechange_attributes
    end

    def robot_exists?
      false
    end
  end
end
