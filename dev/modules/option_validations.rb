# encoding: utf-8
require 'chinese/core_ext/hash'

module Chinese
  module OptionValidations

    # In order to be able to validate options in both
    # instance and singleton methods
    # The following method makes sure that a call to
    # include Chinese::Options makes a available all module
    # method as both instance and singleton methods.
    def self.included(klass)
      klass.extend(self)
    end

    def __methods__
      # If self.class equals Class, then self is not an instance of a class
      # (except for class Class of course),
      # which means we are inside a sigleton method.
      if self.class == Class
        self::Methods
      else  # self is an instance of a class
        self.class::Methods
      end
    end

    def __validations__
      # If self.class equals Class, then self is not an instance of a class
      # (except for class Class of course),
      # which means we are inside a sigleton method.
      if self.class == Class
        self::Validations
      else  # self is an instance of a class
        self.class::Validations
      end
    end


    def validate_options_of(methods, ops, m_const=__methods__, validations=__validations__)
      invalid_keys = __include_invalid_keys__?(methods, ops, m_const)
      raise ArgumentError, "The following key(s) is/are not supported: #{invalid_keys.join(', ')}"  if invalid_keys

      extracted_options = __extract_options__(methods, ops, m_const)

      extracted_options.reduce({}) do |acc, (m, options)|
        result = __validate_all__(m_const[m], options, validations)
        acc.merge!({m => result})
        acc
      end
    end


    # For every method in 'methods', add the supported keys from Methods[:method].
    # Substract from the keys in the options passed.
    # If there are remaining keys in the passed options, these are not supported.
    def __include_invalid_keys__?(methods, ops, m_const=__methods__)
      supported_keys   = methods.map { |m| m_const[m] }.flatten.uniq
      unsupported_keys = ops.delete_keys(*supported_keys).keys
      if unsupported_keys.size > 0
        unsupported_keys
      else
        false
      end
    end


    # Find the supported keys for every method in methods (based on the keys given in Methods['method'])
    # and return a hash of the following kind:
    # {m1 => {key/val pairs found in options}, m2 => {key/val pairs found in options}, ...}
    # NOTE: If no supported keys are found in the options passed for a particular method,
    # an empty array is returned for that method ({..., m => {}, ...}).
    def __extract_options__(methods, ops, m_const=__methods__)
      methods.reduce({}) do |acc, m|
        method_options_hash = extract_options(m, ops, m_const)
        acc.merge!(method_options_hash)
        acc
      end
    end

    def extract_options(m, ops, m_const=__methods__)
      options = ops.slice(*m_const[m])
      Hash[m, options]
    end



    # ops = extracted options (see method '__extract_options__')
    # key = an option key of a method from the array at Methods['method']
    # Validation steps:
    # 1) Return empty hash if there is no entry for this key in Validations
    #    (this is normally the case with options of third-party libraries,
    #    that do their own options validations.)
    # 2) Return a hash {key => 'default_value'} if key was not found in the options.
    # 3) Do the validation. If the validation passes:
    #    -- return hash {key => 'passed value' }, else
    #    -- throw exception "'passed value' is not a valid value"
    def __validate_value_of__(key, ops, validations=__validations__)
      data = validations[key]
      return {} unless data

      default_value = data[0]
      validation    = data[1]
      # If key was not passed as a parameter, return its default value.
      return Hash[key, default_value]  unless ops.has_key?(key)
      value = ops[key]
      # Check if 'value' is a valid value.
      if validation.call(value)
        Hash[key, value]
      else
        raise ArgumentError, "'#{value}' is not a valid value for option :#{key}."
      end
    end



    # ops  = extracted options (see method '__extract_options__')
    # keys = the array of supported keys of a method at Methods['method']
    # Validate every key in keys with __validate_value_of__
    def __validate_all__(keys, ops, validations=__validations__)
      keys.reduce({}) do |hash, key|
        result = __validate_value_of__(key, ops, validations)
        hash.merge!(result)
        hash
      end
    end


    # Often used validation methods
    # =============================

    def is_boolean?(value)
      # Only true for either 'false' or 'true'
      !!value == value
    end

    def is_unicode?(word)
      # Remove all non-ascii and non-unicode word characters
      word = distinct_words(word).join
      # English text at this point only contains characters that are mathed by \w
      # Chinese text at this point contains mostly/only unicode word characters that are not matched by \w.
      # In case of Chinese text the size of 'char_arr' therefore has to be smaller than the size of 'word'
      char_arr = word.scan(/\w/)
      char_arr.size < word.size
    end

    # Input: "除了。。。 以外。。。"
    # Outout: ["除了", "以外"]
    def distinct_words(word)
      # http://stackoverflow.com/a/3976004
      # Alternative: /[[:word:]]+/
      word.scan(/\p{Word}+/)      # Returns an array of characters that belong together.
    end




  end
end
