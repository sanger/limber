require 'ostruct'

module Sequencescape
  class BarcodeLabel < OpenStruct
    extend ActiveModel::Naming
    include ActiveModel::Validations
  end

 class Plate < OpenStruct
   extend ActiveModel::Naming
   include ActiveModel::Validations

   def initialize(name, child_plate_purposes)
     super(
      :barcode              => name,
      :name                 => name,
      :state                => 'pending',
      :child_plate_purposes => child_plate_purposes,

      # TODO Move :states out into the client app
      :states      => {
        'Pending'  => 'pending',
        'Started'  => 'started',
        'Passed'   => 'passed',
        'Canceled' => 'canceled',
        'Failed'   => 'failed'
      }
     )
   end

   def self.find(uuid)
    self.new(uuid, Sequencescape::ASSETS[uuid])
   end

   def update_attributes!(params)
    params.each { |k,v| send("#{k}=", v) }
   end

   def size
     96
   end

   def summary
    "Some information about the plate that has just been created and the plate that it was made from."
   end
 end

 class Tube < OpenStruct
   def initialize(name)
     super(:barcode => name, :state => 'pending')
   end
 end

 class PlatePurpose < OpenStruct
   extend ActiveModel::Naming
   include ActiveModel::Validations

   def self.find(uuid)
    self.new(uuid)
   end
   def initialize(name)
     super(:name => name)
   end
 end

 # Pre-generate all of the plates so that they are maintained (particularly the state)
 ASSETS = Hash[
   { # Barcode                                  UUID
     'StockPlate'                        => [ 'WgsFragmentationPlate' ],
     'QcPlate'                           => [ ],
     'WgsFragmentationPlate'             => [ 'WgsFragmentationPurificationPlate' ],
     'WgsFragmentationPurificationPlate' => [ 'WgsLibraryPreparationPlate', 'QcPlate' ],
     'WgsLibraryPreparationPlate'        => [ 'WgsLibraryPlate', 'QcPlate' ],
     'WgsLibraryPlate'                   => [ 'WgsLibraryPcrPlate' ],
     'WgsLibraryPcrPlate'                => [ 'WgsAmplifiedLibraryPlate' ],
     'WgsAmplifiedLibraryPlate'          => [ 'WgsPooledAmplifiedLibraryPlate' ],
     'WgsPooledAmplifiedLibraryPlate'    => [ ]
   }.map do |barcode, child_plate_purposes|
     [ barcode, Plate.new(barcode, child_plate_purposes.map(&PlatePurpose.method(:new))) ]
   end + [
     [ 'LoadingTube', Tube.new('LoadingTube') ]
   ]
 ]

 class Api
   class Search
     def self.find(uuid)
       case uuid
       when 'find asset by barcode' then ByAssetBarcode.new
       when 'find user by barcode'  then ByUserBarcode.new
       else raise StandardError, "Unimplemented search #{uuid.inspect}"
       end
     end

     class ByAssetBarcode
       def first(options)
         Sequencescape::ASSETS[options[:barcode]] or raise StandardError, "Unimplemented asset barcode #{options.inspect}"
       end
     end

     class ByUserBarcode
       class User
         def name
           'John Smith'
         end

         def barcode
           'user'
         end
       end

       def first(options)
         raise StandardError, "Unimplemented user barcode #{options[:barcode]}" unless options[:barcode] == 'user'
         User.new
       end
     end
   end

   def search
     Search
   end

   class PlateCreation
     def self.create!(attributes)
       OpenStruct.new(attributes.merge(:child => Sequencescape::ASSETS[attributes[:child_plate_purpose].name]))
     end
   end

   def plate_creation
     PlateCreation
   end

   def plate
    Plate
   end

   def plate_purpose
    PlatePurpose
   end
   
   class TagLayoutTemplate
     class TagLayout
     end
     
     def self.all
       {
         '1 to 8(columns) - Standard Illumina 10mer' => '1_TO_8_STANDARD_ILLUMINA_10MER',
         'Daft Punk is playing in my house, in my house...' => 'blah_blah_blah'
       }
     end
     
     def self.find(uuid)
       case uuid
       when '1 to 8 (columns)' then TagLayoutTemplate.new
       when '1 to 12 (rows)'   then TagLayoutTemplate.new
       when '96 (plate)'       then TagLayoutTemplate.new
       else raise StandardError, "Unimplemented tag layout #{uuid.inspect}"
       end
     end

     def create!(attributes)
       OpenStruct.new(attributes)
     end
   end

   def tag_layout_template
     TagLayoutTemplate
   end

   class TransferTemplate
     def self.all
       {
         'Whole Plate' => 'Plate-to-plate',
         '1 only'      => '1_only',
         '1 to 2'      => '1_to_2',
         '1 to 3'      => '1_to_3',
         '1 to 4'      => '1_to_4',
         '1 to 6'      => '1_to_6'
       }
     end
     
     def self.find(uuid)
       case uuid
       when '1_only'         then TransferTemplate.new
       when '1_to_2'         then TransferTemplate.new
       when '1_to_3'         then TransferTemplate.new
       when '1_to_4'         then TransferTemplate.new
       when '1_to_6'         then TransferTemplate.new
       when 'Plate-to-plate' then TransferTemplate.new
       end
     end

     def create!(attributes)
       OpenStruct.new(attributes)
     end
   end

   def transfer_template
     TransferTemplate
   end

   class StateChange
     def self.create!(attributes)
       OpenStruct.new(attributes.merge(:previous_state => attributes[:target].state)).tap do
         attributes[:target].state = attributes[:target_state]
       end
     end
   end

   def state_change
     StateChange
   end
 end
end
