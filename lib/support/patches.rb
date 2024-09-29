# frozen_string_literal: true

# simplest monkey patch, honest ;)
class Object
  # Only define blank? if it's not already defined
  unless method_defined?(:blank?)
    def blank?
      respond_to?(:empty?) ? empty? : !self
    end
  end
end
