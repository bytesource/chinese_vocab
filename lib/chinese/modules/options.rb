# encoding: utf-8

module Chinese
  module Options

    # In order to be able to validate options in both
    # instance and singleton methods,
    # the following method makes sure that all module methods are available
    # as both instance and singleton methods.
    def self.included(klass)
      klass.extend(self)
    end


    # Validates the options passed in the block.
    #  Options can either be a single option key or an array of options keys.
    #  Option keys and their values are validated based on the information given in a
    #  mandatory constant called `OPTIONS`. Keys from a methods `options` has that are not listed in `OPTIONS` are ignored.
    # @note A class that includes this module is required to:
    #
    #  * have a constant named `OPTIONS` with a hash of the following type:
    #   `{ option_key => [default_value, validation_proc], ...}`.
    #  * to name the optional option hash of a method `options`.
    # @example
    #   class TestClass
    #     include 'Options'
    #
    #     # option_key => [default_value, validation_proc]
    #     OPTIONS = {:compact      => [false, lambda {|value| is_boolean?(value) }],
    #                :with_pinyin  => [true,  lambda {|value| is_boolean?(value) }],
    #                :thread_count => [8,     lambda {|value| value.kind_of?(Integer) }]}
    #
    #     def test_method_1(options={})
    #       @thread_count = validate { :thread_count }
    #       # ...
    #     end
    #
    #     def self.test_method_2(options={})
    #       @compact, @with_pinyin = validate { [:compact, :with_pinyin] }
    #       # ...
    #     end
    #
    #     #...
    #   end
    def validate(&block)
      raise ArgumentError, "No block given" unless block

      argument = block.call
      # Raise exception if the block is empty.
      raise ArgumentError, "Block is empty"  if argument.nil?

      keys = Array(argument) # Wrap single key as array. If passed an array, just return the array.

      constant = eval("OPTIONS", block.binding)
      options  = eval("options", block.binding) # Alternative: constant = block.binding.eval("OPTIONS")

      values = keys.map do |key|
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

      values.size > 1 ? values : values [0]
    end

    # Returns a new hash from `options` based on the keys provided
    #  in `arr`. Keys in `arr` not found in `options` are ignored.
    #  *Use case*: When a method's options hash contains options for another method
    #  that throws an exeption if the options hash contains keys not handled internally (Example: CSV library)
    #  the options special to that method need to be extracted before passed as an argument.
    # @example
    #   def sample_method(text, options={})
    #     @compact, @with_pinyin = validate { [:compact, :with_pinyin] }
    #
    #     csv_options = extract_options(CSV::DEFAULT_OPTIONS.keys, options)
    #     csv = CSV.parse(text, csv_options)
    #     #...
    #   end
    def extract_options(arr, options)
      options.slice(*arr)
    end



    # Some useful validation methods
    # =============================

    # Helper method that can be used in a validation proc.
    # @return [true, false] Returns `true` is the argument passed is either `true` or `false`.
    #   Returns `false` on any other argument.
    def is_boolean?(value)
      # Only true for either 'false' or 'true'
      !!value == value
    end

  end
end
