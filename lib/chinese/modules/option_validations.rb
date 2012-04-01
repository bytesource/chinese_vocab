# encoding: utf-8

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


    def __object__
      # If self.class equals Class, then self is not an instance of a class
      # (except for class Class of course),
      # which means we are inside a sigleton method.
      if self.class == Class
        self::Options
      else  # self is an instance of a class
        self.class::Options
      end
    end


    # Example usage:
    # validate(:source, options, lambda {|val| [:nciku, :jukuu].include?(val) }, :nciku)
    def validate_value(options, key, validation = __object__, default_value)
      # If key was not passed as a parameter, return its default value.
      return default_value  unless options.has_key?(key)

      value = options[key]
      # Check if 'value' is a valid value.
      if validation[key][0].call(value)
        value
      else
        raise ArgumentError, "'#{value}' is not a valid value for option :#{key}."
      end
    end

    def validate_keys(options, validation = __object__, method = __callee__)

    end


    def __option_keys__(method_name, data)
      puts "data #{data}"
      data.select do |key, value|
      puts "key #{key}"
      puts "array #{value}"
      value[1].include?(method_name)
      end.keys
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
