# frozen_string_literal: true

class Labels::PlateLabelBase < Labels::Base # rubocop:todo Style/Documentation
  def attributes
    {
      top_left: date_today,
      bottom_left: labware.barcode.human,
      top_right: workline_identifier,
      bottom_right: [labware.role, labware.purpose.name].compact.join(' '),
      barcode: labware.barcode.machine
    }
  end

  def sprint_attributes
    {
      a: date_today,
      b: labware.barcode.human,
      c: workline_identifier,
      d: [labware.role, labware.purpose.name].compact.join(' '),
      e: labware.barcode.machine,
      f: 'hello'
    }
  end

  def qc_attributes # rubocop:todo Metrics/MethodLength
    [
      {
        g: 'QC 1',
        h: "QC 1",
        i: "QC 1"
      },
      {
        j: "QC 2",
        k: 'QC 2'
      }
    ]
  end

  def intermediate_attributes # rubocop:todo Metrics/MethodLength
    [
      {
        l: 'Int 1',
        m: labware.barcode.human,
        n: labware.stock_plate&.barcode&.human,
        o: [labware.role, 'LDS Lig'].compact.join(' '),
        p: [labware.barcode.human, 'LIG'].compact.join('-')
      },
      {
        q: 'Int 2',
        r: labware.barcode.human,
        s: labware.stock_plate&.barcode&.human,
        t: [labware.role, 'LDS A-tail'].compact.join(' '),
        u: [labware.barcode.human, 'ATL'].compact.join('-')
      },
      {
        v: 'Int 3',
        w: labware.barcode.human,
        x: labware.stock_plate&.barcode&.human,
        y: [labware.role, 'LDS Frag'].compact.join(' '),
        z: [labware.barcode.human, 'FRG'].compact.join('-')
      }
    ]
  end

  def default_printer_type
    default_printer_type_for(:plate_a)
  end

  def default_label_template
    default_label_template_for(:plate_a)
  end

  def default_sprint_label_template
    default_sprint_label_template_for(:plate_a)
  end
end
