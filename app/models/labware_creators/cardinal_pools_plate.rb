module LabwareCreators
  class CardinalPoolsPlate < Base 
    # def initialise(parent_plate)
    #   config = get_cardinal_pooled_plate_config
    #   parent_plate = parent_plate # LCA PBMC is the parent plate
    # end

    @@pooling_config = {}

    # CardinalPoolsPlate.pooling_config ==> 
    def self.pooling_config
      @@pooling_config
    end

    def self.pooling_config=(config)
      @@pooling_config = config
    end


    # 1. Create a new empty LCA PBMC Pools plate

    # 2. Get the number of not failed samples in the parent (LCA PBMC) plate
    
    # 3. Look up the pooling config for that number 
    # e.g. if there are 96 passed wells on the parent, the samples get split into 8 pools, with 12 samples per pool.

    # 4. Group samples using group size from above, where random samples are used in the pool

    # 5. Add the group of samples (pool) to a well in the new LCA PBMC Pools plate
  end
end