# frozen_string_literal: true

# A primer panel is a selection of pcr primers targeted at
# specific location on the DNA in order to amplify known SNP
# sites. (SNP = Single nucleotide polymorphism, a region of DNA
# know to vary between individuals)
# It is specified as a property on pool during submission, and
# also directs the use of specific PCR programs at particular
# point during the process.
class PrimerPanel
  UNKNOWN = 'Unknown'
  attr_reader :name

  def initialize(panel_config_hash)
    panel_config_hash ||= {}
    @name = panel_config_hash.fetch('name', UNKNOWN)
    @programs = panel_config_hash.fetch('programs', {})
  end

  def program_name_for(step)
    program_for(step).fetch('name', UNKNOWN)
  end

  def program_duration_for(step)
    program_for(step).fetch('duration', UNKNOWN)
  end

  private

  def program_for(step)
    @programs.fetch(step, {})
  end
end
