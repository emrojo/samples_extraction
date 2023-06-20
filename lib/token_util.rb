module TokenUtil # rubocop:todo Style/Documentation
  LOCATION_REGEXP = /^([A-H])(\d{1,2})$/.freeze
  UUID_REGEXP = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.freeze
  MACHINE_BARCODE = /^\d*$/.freeze
  HUMAN_BARCODE = /^\w*$/.freeze
  WILDCARD_REGEXP = /\?\w*/.freeze

  def self.fluidx_barcode_prefix
    'F'
  end

  def self.invalid_barcode?(barcode)
    barcode.nil? || (barcode.kind_of?(String) && barcode.to_s.empty?)
  end

  def self.machine_barcode?(barcode)
    return false if invalid_barcode?(barcode)

    barcode.to_s.match?(MACHINE_BARCODE)
  end

  def self.human_barcode?(barcode)
    return false if invalid_barcode?(barcode)

    # If we change the next line, we should change it to check the regexp
    !machine_barcode?(barcode)
  end

  def self.machine_barcode(barcode)
    return SBCF::SangerBarcode.from_human(barcode).machine_barcode.to_s if human_barcode?(barcode)

    barcode.to_s
  end

  def self.human_barcode(barcode)
    return SBCF::SangerBarcode.from_machine(barcode).human_barcode.to_s if machine_barcode?(barcode)

    barcode.to_s
  end

  def self.is_uuid?(str)
    str.kind_of?(String) && !str.match(UUID_REGEXP).nil?
  end

  def self.quote_if_uuid(str)
    return quote(str) if is_uuid?(str)

    return str
  end

  def self.is_valid_fluidx_barcode?(barcode)
    barcode.to_s.starts_with?(fluidx_barcode_prefix)
  end

  def self.uuid(str)
    str.match(UUID_REGEXP)[0]
  end

  def self.is_wildcard?(str)
    str.kind_of?(String) && !str.match(WILDCARD_REGEXP).nil?
  end

  def self.kind_of_asset_id?(str)
    !!(str.kind_of?(String) && (is_wildcard?(str) || is_uuid?(str)))
  end

  def self.to_asset_group_name(wildcard)
    wildcard&.delete('?')
  end

  def self.generate_positions(rows, columns)
    columns.flat_map { |col| rows.map { |row| "#{row}#{pad(col, '0', 2)}" } }
  end

  def self.pad(str, chr, size)
    str.rjust(size, chr)
  end

  def self.unpad_location(location)
    return location unless location

    location.match(/(\w)0*(\d*)/).captures.join
  end

  def self.pad_location(location)
    return location unless location

    letter, number = location.match(LOCATION_REGEXP)&.captures || raise("Invalid location: #{location}")
    "#{letter}#{pad(number, '0', 2)}"
  end

  def self.quote(str)
    return str unless str

    "\"#{str}\""
  end

  def self.unquote(str)
    str&.delete('"')
  end
end
