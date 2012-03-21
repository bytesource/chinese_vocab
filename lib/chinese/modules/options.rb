# encoding: utf-8

module Chinese
  module Options

    # In order to be able to validate options in both
    # instance and singleton methods
    # The following method makes sure that a call to
    # include Chinese::Options makes a available all module
    # method as both instance and singleton methods.
    def self.included(klass)
      klass.extend(self)
    end


    # Example usage:
    # validate(:source, options, lambda {|val| [:nciku, :jukuu].include?(val) }, :nciku)
    def validate(key, options, validation, default_value)
      # If key was not passed as a parameter, return its default value.
      return default_value  unless options.has_key?(key)

      value = options[key]
      # Check if 'value' is a valid value.
      if validation.call(value)
        value
      else
        raise ArgumentError, "'#{value}' is not a valid value for option :#{key}."
      end
    end


    # Often used validation methods
    # =============================

    def is_boolean?(value)
      # Only true for either 'false' or 'true'
      !!value == value
    end



  end
end
