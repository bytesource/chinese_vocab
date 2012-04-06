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

    # def __validation_constant__
    #   # If self.class equals Class, then self is not an instance of a class
    #   # (except for class Class of course),
    #   # which means we are inside a sigleton method.
    #   if self.class == Class
    #     self::Validations
    #   else  # self is an instance of a class
    #     self.class::Validations
    #   end
    # end


    # # Example usage:
    # # validate(:source, options, lambda {|val| [:nciku, :jukuu].include?(val) }, :nciku)
    # def validate(options, key, validation=__validation_constant__[key], default_value)
    #   # If key was not passed as a parameter, return its default value.
    #   return default_value  unless options.has_key?(key)

    #   value = options[key]
    #   # Check if 'value' is a valid value.
    #   if validation.call(value)
    #     value
    #   else
    #     raise ArgumentError, "'#{value}' is not a valid value for option :#{key}."
    #   end
    # end

    def validate(&block)
      raise ArgumentError, "No block given" unless block

      argument = block.call
      # Raise exception if the block is empty.
      raise ArgumentError, "Block is empty"  if argument.nil?

      keys = []
      case argument
      when Symbol, String  # Single key
        keys = [argument]
      when Array           # Array of keys
        keys = argument
      else                 # Wrong type => raise exception
        raise ArgumentError,
          "Invalid argument '#{argument}'. \nYou can either pass a single key (Symbol) or several keys (Array of Symbols)."
      end

      constant = eval("OPTIONS", block.binding)
      options  = eval("options", block.binding) # Alternative: constant = block.binding.eval("OPTIONS")

      values = keys.map do |key|
        key = key.to_sym
        # Raise exception if 'key' is NOT a key in the OPTIONS constant.
        raise ArgumentError, "Key '#{key}' not found in OPTIONS" unless constant.keys.include?(key)

        if options.has_key?(key) # Supported key in block found in options => extract its value from options.
          value = options[key]
          # Check if 'value' is a valid value.
          validation = constant[key][1]
          if validation.call(value)    # Validation passed => return value from options
            value
          else                         # Validation failed => raise exception
            raise ArgumentError, "'#{value}' (#{value.class}) is not a valid value for key '#{key}'."
          end
        else # Supported key in block not found in options => return its default value.
          default_value = constant[key][0]
          default_value
        end
      end

      if values.size > 1 # More than one return value => return array
        values
      else               # Single return value => return value
        values[0]
      end
    end


    def extract_options(arr, options)
      options.slice(*arr)
    end



    # Some useful validation methods
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
