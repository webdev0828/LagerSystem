ActionView::Helpers::FormBuilder.class_eval do

  def localized_number_field(field, options = {})
    options[:value] = ActionController::Base.helpers.number_with_precision object.send(:"#{field}_before_type_cast"), {
      :strip_insignificant_zeros => true,
      :precision => 3,
      :delimiter => ''
    }
    text_field(field, options)
  end

end

ActiveRecord::Base.class_eval do

  def self.localize_numbers_for(*fields)
    # TODO: Read config before assuming delimiter and separator
    fields.each do |field|
      define_method "#{field}=" do |value|
        write_attribute(field, valid_number?(value) ? value.to_s.gsub(",", ".") : value)
      end
    end
  end

  private

  def valid_number?(value)
    value.to_s.match(/\A\s*[-]?(\d+)(,\d*)?\s*\Z/) != nil
  end

end