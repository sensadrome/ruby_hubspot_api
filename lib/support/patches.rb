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

# At some point this will seem like a bad idea ;)

# :nocov:
if RUBY_VERSION < '2.5.0'
  class Hash
    # Non-mutating version (returns a new hash with transformed keys)
    def transform_keys
      return enum_for(:transform_keys) unless block_given?
      result = {}
      each_key do |key|
        result[yield(key)] = self[key]
      end
      result
    end

    # Mutating version (modifies the hash in place)
    def transform_keys!
      return enum_for(:transform_keys!) unless block_given?
      keys.each do |key|
        self[yield(key)] = delete(key)
      end
      self
    end
  end
end
# :nocov:end
