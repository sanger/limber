module LabWareHelper
  def state_change_form(presenter)
    render :partial => 'lab_ware/state_change', :locals => { :presenter => presenter }
  end

  STANDARD_COLOURS = (1..96).map { |i| "colour-#{i}" }
  FAILED_STATES    = [ 'failed', 'cancelled' ]

  def self.cycling_colours(name, &block)
    define_method(:"#{name}_colour") do |*args|
      return 'failed' if FAILED_STATES.include?(args.first)  # First argument is always the well
      @colours  ||= Hash.new { |h,k| h[k] = STANDARD_COLOURS.dup }
      @rotating ||= Hash.new { |h,k| h[k] = @colours[name].rotate!.first }
      @rotating[block.call(*args)]
    end
  end

  cycling_colours(:bait)    { |lab_ware, _|          lab_ware.bait }
  cycling_colours(:tag)     { |lab_ware, _|          lab_ware.aliquots.first.tag.identifier }
  cycling_colours(:pooling) { |lab_ware,destination| destination }

  def aliquot_colour(lab_ware)
    case lab_ware.state
      when "passed"   then "green"
      when "started"  then "orange"
      when "failed"   then "red"
      when "canceled" then "red"
      else "blue"
    end
  end
end
