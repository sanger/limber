# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'submission_pool factories' do
  describe 'basic' do
    subject do
      json(
        :submission_pool_collection,
        plate_uuid: 'plate-uuid'
      )
    end

    let(:json_content) do
      # Submission pools are a bit weird in that they don't have a uuid, as ultimately they are just
      # a different representation of a submission. If you tried to fetch them by the submission
      # uuid, you'd get the submission itself.
      %({
        "actions": {
          "read": "http://example.com:3000/plate-uuid/submission_pools/1",
          "first": "http://example.com:3000/plate-uuid/submission_pools/1",
          "last": "http://example.com:3000/plate-uuid/submission_pools/1"
        },
        "size": 1,
        "submission_pools": [
          {
            "plates_in_submission": 1,
            "used_tag2_layout_templates": [],
            "used_tag_layout_templates": []
          }
        ]
      })
    end

    it 'should match the expected json' do
      expect(JSON.parse(subject)).to eq JSON.parse(json_content)
    end
  end

  describe 'dual indexed' do
    subject do
      json(
        :dual_submission_pool_collection,
        plate_uuid: 'plate-uuid'
      )
    end

    let(:json_content) do
      # Submission pools are a bit weird in that they don't have a uuid, as ultimately they are just
      # a different representation of a submission. If you tried to fetch them by the submission
      # uuid, you'd get the submission itself.
      %({
        "actions": {
          "read": "http://example.com:3000/plate-uuid/submission_pools/1",
          "first": "http://example.com:3000/plate-uuid/submission_pools/1",
          "last": "http://example.com:3000/plate-uuid/submission_pools/1"
        },
        "size": 1,
        "submission_pools": [
          {
            "plates_in_submission": 2,
            "used_tag2_layout_templates": [],
            "used_tag_layout_templates": []
          }
        ]
      })
    end

    it 'should match the expected json' do
      expect(JSON.parse(subject)).to eq JSON.parse(json_content)
    end
  end

  describe 'with used templates' do
    subject do
      json(
        :dual_submission_pool_collection,
        plate_uuid: 'plate-uuid',
        used_tag2_templates: [{ "uuid": 'used-tag2-template-uuid', "name": 'Used template' }],
        used_tag_templates: [{ "uuid": 'used-tag-template-uuid', "name": 'Used template' }]
      )
    end

    let(:json_content) do
      # Submission pools are a bit weird in that they don't have a uuid, as ultimately they are just
      # a different representation of a submission. If you tried to fetch them by the submission
      # uuid, you'd get the submission itself.
      %({
        "actions": {
          "read": "http://example.com:3000/plate-uuid/submission_pools/1",
          "first": "http://example.com:3000/plate-uuid/submission_pools/1",
          "last": "http://example.com:3000/plate-uuid/submission_pools/1"
        },
        "size": 1,
        "submission_pools": [
          {
            "plates_in_submission": 2,
            "used_tag2_layout_templates": [{"uuid": "used-tag2-template-uuid", "name": "Used template"}],
            "used_tag_layout_templates": [{"uuid": "used-tag-template-uuid", "name": "Used template"}]
          }
        ]
      })
    end
    it 'should match the expected json' do
      expect(JSON.parse(subject)).to eq JSON.parse(json_content)
    end
  end
end
