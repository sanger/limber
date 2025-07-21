# frozen_string_literal: true

# Represents a tube rack in the system
class Limber::TubeRack
  def purpose
    tube_rack_purpose
  end

  def plate?
    false
  end

  def tube?
    false
  end

  def tube_rack?
    true
  end
end
