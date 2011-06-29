module PlateWalking
  def wells_by_row
    plate_to_walk.wells.inject(Hash.new {|h,k| h[k]=[]}) do |h,well|
      h[well.location.sub(/\d+/,'')] << well; h
    end
  end
end
