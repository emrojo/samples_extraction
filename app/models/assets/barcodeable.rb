module Assets::Barcodeable
  def build_barcode(index)
    self.barcode = SBCF::SangerBarcode.new({
      prefix: Rails.application.config.barcode_prefix,
      number: index
    }).human_barcode
  end

  def generate_barcode
    save
    if barcode.nil?
      update_attributes({
        barcode: SBCF::SangerBarcode.new({
          prefix: Rails.application.config.barcode_prefix,
          number: self.id
          }).human_barcode
        }
      )
    end
  end
end
