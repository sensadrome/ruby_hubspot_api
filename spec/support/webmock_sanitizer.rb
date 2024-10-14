# frozen_string_literal: true

module WebMockRequestSignatureSanitizer
  # Prepend this module to WebMock::RequestSignature
  def to_s
    str = super.dup

    self.class.sensitive_data_filters.each do |pattern, replacement|
      str.gsub!(pattern, replacement.to_s)
      str.gsub!(Regexp.escape(pattern.to_s), replacement.to_s)
    end

    str
  end

  module ClassMethods
    def sensitive_data_filters
      @sensitive_data_filters ||= {}
    end

    def filter_sensitive_data(replacements)
      sensitive_data_filters.merge!(replacements)
    end
  end

  def self.prepended(base)
    base.singleton_class.prepend(ClassMethods)
  end
end

# Prepend the module to WebMock::RequestSignature
WebMock::RequestSignature.prepend(WebMockRequestSignatureSanitizer)

%w[HUBSPOT_ACCESS_TOKEN HUBSPOT_CLIENT_SECRET HUBSPOT_PORTAL_ID].each do |secret|
  next unless ENV[secret]

  WebMock::RequestSignature.filter_sensitive_data(
    ENV[secret] => "<#{secret} [filtered]>"
  )
end
