ActiveModel::Translation.send(:alias_method, :attr_name, :human_attribute_name)

ActiveRecord::Base.class_eval do

  def each_human_name_and_value( *attrs )
    options = attrs.extract_options!
    omit_blanks = !options[:blanks]
    if block_given?
      attrs.each do |n|
        val  = self.send(n)
        next if omit_blanks and val.blank?
        human_name = self.class.human_attribute_name(n)
        yield(human_name, val)
      end
    end
  end

end
