module PlateWalking
  def wells_by_row
    Walker.new(plate_to_walk.wells)
  end

  class Walker
    def initialize(wells)
      @rows = wells.inject(Hash.new {|h,k| h[k]=[]}) do |h,well|
        h[well.location.sub(/\d+/,'')] << well; h
      end.tap do |rows|
        rows.each do |_, row|
          row.sort! { |a,b| a.location.sub(/\D+/,'').to_i <=> b.location.sub(/\D+/,'').to_i }
        end
      end
    end

    delegate :each, :to => :@rows
  end
end
