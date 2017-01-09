# frozen_string_literal: true
# Provides some specialized behaviour for handling tube transfers.
# Not instantiated directly through eg. api.transfer.find(...)
# but instead when loaded via the association on plate.
class Limber::TubeTransfer < ::Sequencescape::Transfer
  belongs_to :source, class_name: 'Limber::Plate', disposition: :inline
  attribute_reader :transfers

  def transfers=(transfers)
    super(Hash[
        transfers.map do |well, tube_json|
          [well, ::Limber::StockLibraryTube.new(api, tube_json, false)]
        end
      ]
    )
  end
end
