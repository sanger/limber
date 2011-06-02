require 'ostruct'

module Sequencescape
  class BarcodeLabel < OpenStruct
    include ActiveModel::Validations
    include ActiveModel::Naming
  end
  
 class Plate < OpenStruct
   include ActiveModel::Naming
   include ActiveModel::Validations
   
   def initialize(name, child_plate_purposes)
     super(
      :barcode              => name, 
      :state                => 'pending', 
      :child_plate_purposes => child_plate_purposes,
      :states => {
        'Pending' => 'pending', 
        'Passed'  => 'passed', 
        'Failed'  => 'failed'
      }
     )
   end
   
   def update_attribute!(params)
    params.each do |k,v|
      send("#{k}=", v)
    end
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
   def initialize(name)
     super(:name => name)
   end
 end

 # Pre-generate all of the plates so that they are maintained (particularly the state)
 ASSETS = Hash[
   { # Barcode                                  UUID
     'StockPlate'                        => [ 'WGSFragmentationPlate' ],
     'QCPlate'                           => [ ],
     'WGSFragmentationPlate'             => [ 'WGSFragmentationPurificationPlate' ],
     'WGSFragmentationPurificationPlate' => [ 'WGSLibraryPreparationPlate', 'QCPlate' ],
     'WGSLibraryPreparationPlate'        => [ 'WGSLibraryPlate', 'QCPlate' ],
     'WGSLibraryPlate'                   => [ 'WGSLibraryPCRPlate' ],
     'WGSLibraryPCRPlate'                => [ 'WGSAmplifiedLibraryPlate' ],
     'WGSAmplifiedLibraryPlate'          => [ 'WGSPooledAmplifiedLibraryPlate' ],
     'WGSPooledAmplifiedLibraryPlate'    => [ ]
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

   class TagLayoutTemplate
     class TagLayout

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
     def self.find(uuid)
       case uuid
       when '1 only'         then TransferTemplate.new
       when '1 to 2'         then TransferTemplate.new
       when '1 to 3'         then TransferTemplate.new
       when '1 to 4'         then TransferTemplate.new
       when '1 to 6'         then TransferTemplate.new
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