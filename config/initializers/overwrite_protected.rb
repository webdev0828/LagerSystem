module ActiveRecord
  module Acts
    module OverwriteProtected
      def self.included(base)
        base.extend(ClassMethods)
      end

      # This +acts_as+ extension provides overwrite protection for the model.
      # An attribute +lock_token+ is added. A validation is added that require +lock_token+ to
      # be +nil+ or match the token provided by +generate_lock_token+.
      module ClassMethods

        # Make model act like overwrite protected
        def acts_as_overwrite_protected
          class_eval do
            include ActiveRecord::Acts::OverwriteProtected::InstanceMethods

            validate do
              unless lock_token.nil? or lock_token_accepted?
                errors.add(:base, :overwrite_protected)
              end
            end
          end
        end
      end

      module InstanceMethods

        attr_accessor :lock_token

        # Check if lock_token is accepted
        def lock_token_accepted?
          generate_lock_token.to_s == lock_token
        end

        private

        # Generate a lock token using cache_key.
        # This method can be overwritten for specialized behaviour.
        def generate_lock_token
          cache_key
        end

      end
    end
  end
end


ActiveRecord::Base.class_eval do
  include ActiveRecord::Acts::OverwriteProtected
end

ActionView::Helpers::FormHelper.class_eval do

  def protected_form_for(record, options = {})
    raise ArgumentError, "Missing block" unless block_given?

    object = record.is_a?(Array) ? record.last : record
    unless object.respond_to?(:lock_token) and object.respond_to?(:generate_lock_token, true)
      raise ArgumentError, "Record does not act as overwrite protected."
    end

    form_for(record, options) do |f|
      lock_token_tag = f.hidden_field(:lock_token, :value => object.lock_token || object.send(:generate_lock_token))
      concat content_tag(:div, lock_token_tag, :style => 'margin:0;padding:0;display:inline')
      yield f
    end
  end

end

