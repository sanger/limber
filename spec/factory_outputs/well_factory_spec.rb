# frozen_string_literal: true
require 'rails_helper'

describe 'well factory' do
  subject do
    json(
      :well,
      uuid: 'example-well-uuid'
    )
  end

  # This is a massive oversimplification of the well json, as there is a LOT
  # of unecessary information. We trim our mocks down to what we actually NEED
  let(:json_content) do
    %({
      "well": {
        "created_at": "2016-11-17 11:08:33 +0000",
        "updated_at": "2016-11-17 11:08:53 +0000",
        "actions": {
          "read": "http://sequencescape.psd.sanger.ac.uk:6600/api/1/example-well-uuid"
        },
        "uuid": "example-well-uuid",
        "aliquots":[{
            "created_at": "2016-11-17 11:08:53 +0000",
            "updated_at": "2016-11-17 11:08:53 +0000",
            "bait_library":null,
            "insert_size": {},
            "sample": {
              "created_at": "2016-11-10 09:34:49 +0000",
              "updated_at": "2016-11-10 09:34:49 +0000",
              "actions": {
                "read": "http://sequencescape.psd.sanger.ac.uk:6600/api/1/example-sample-uuid"
              },
              "uuid": "example-sample-uuid",
              "data_release": {
                  "accession_number":null,
                  "description":null,
                  "managed": {
                    "disease":null,
                    "subject":null,
                    "treatment":null
                  },
                  "metagenomics": {
                    "age":null,
                    "cell_type":null,
                    "compound":null,
                    "developmental_stage":null,
                    "disease":null,
                    "disease_state":null,
                    "dose":null,
                    "genotype":null,
                    "growth_condition":null,
                    "immunoprecipitate":null,
                    "organism_part":null,
                    "phenotype":null,
                    "rnai":null,
                    "subject":null,
                    "time_point":null,
                    "treatment":null
                  },
                  "public_name":null,
                  "sample_type":null,
                  "visibility":null
                },
                "family": {
                  "father":null,
                  "mother":null,
                  "replicate":null,
                  "sibling":null
                },
                "reference": {
                  "genome": "Homo_sapiens (1000Genomes_hs37d5 + ensembl_75_transcriptome)"
                },
                "sanger": {
                  "description":null,
                  "name": "3940STDY6625696",
                  "resubmitted":null,
                  "sample_id": "3940STDY6625696"
                },
                "source": {
                  "cohort":null,
                  "control":null,
                  "country":null,
                  "dna_source":null,
                  "ethnicity":null,
                  "region":null
                },
                "supplier": {
                  "collection": {
                    "date":null
                  },
                  "extraction": {
                    "date":null,
                    "method":null
                  },
                  "measurements": {
                    "concentration":null,
                    "concentration_determined_by":null,
                    "gc_content":null,
                    "gender":null,
                    "volume":null
                  },
                  "purification": {
                    "method":null,
                    "purified":null
                  },
                  "sample_name":null,
                  "storage_conditions":null,
                  "taxonomy": {
                    "common_name":null,
                    "id":null,
                    "organism":null,
                    "strain":null
                  }
                },
                "tag": {}
              }
            ],
            "state": "pending"
          }
      }
  )
  end

  it 'should match the expected json' do
    pending 'the factories'
    expect(JSON.parse(subject)['plate']).to eq JSON.parse(json_content)['plate']
  end
end
