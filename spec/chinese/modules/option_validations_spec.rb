# encoding: utf-8

require 'spec_helper'

describe Chinese::OptionValidations do

  let(:mod)     { described_class }
  let(:methods) { mod.instance_methods(false) }


  context "Inspecting methods" do

    specify { methods.should == [] }

  end

  context "When including the module" do

      class TestClass
        include Chinese::OptionValidations

        require 'csv'

        # option_key => [default_value, validation]
        # Constant required by the 'validate_options' method of the 'OptionValidations' module
        Validations = {with_pinyin: [true,     lambda {|value| is_boolean?(value) }],
                       size:        [:average, lambda {|value| [:short, :average, :long].include?(value) }]}

        # method_name => [option_key, ...]
        # Constant required by the 'validate_options' method of the 'OptionValidations' module
        Methods    = {test_validation: [:with_pinyin, :size],
                      helper_method:   [:with_pinyin, :size],
                      csv:             CSV::DEFAULT_OPTIONS.keys}


        def test_validation(options={})
          ops = validate_options_of(__callee__, :csv)

          helper_method(ops[:helper_method])

          CSV.parse("1,2,3", ops[:csv])
        end

        def helper_method(options={})
          # uses :with_pinyin, :size
        end
      end


    it "should add its methods as instance methods of the class" do

      methods.each do |m|
        TestClass.new.respond_to?(m).should be_true
      end
    end

    it "should add its methods as singleton methods of the class" do

      methods.each do |m|
        TestClass.respond_to?(m).should be_true
      end
    end

    context :__extract_options__ do

      options = {source: :jukuu, size: :short}
      specify { TestClass.new.__extract_options__([:csv, :helper_method], options).should ==
                {:csv=>{}, :helper_method=>{:size=>:short}} }
    end

    context :__include_invalid_keys__? do

      options2 = {size: :short}
      specify { TestClass.new.__include_invalid_keys__?([:csv, :helper_method], options2).should be_false }

      options3 = {source: :jukuu, size: :short}
      specify { TestClass.new.__include_invalid_keys__?([:csv, :helper_method], options3).should == [:source] }

    end

    context :__validate__value_of__ do

      # :size is a supported key.
      # Key is present in options with a valid value.
      # => Return hash {:size => valid_value}
      options4 = {size: :long}
      specify { TestClass.new.__validate_value_of__(:size, options4).should == {:size=>:long} }

      # :size is a supported key.
      # Key is NOT present in options.
      # => Return hash {:size => default_value}
      options5 = {not_the_correct_key: 'some_value'}
      specify { TestClass.new.__validate_value_of__(:size, options5).should == {:size => :average} }

      it "should throw an exception if a key value is invalid" do

        # :size is a supported key.
        # Key is present in options, but with an invalid key.
        # => Throw exception.
        options6 = {size: 'invalid'}
        lambda do
          TestClass.new.__validate_value_of__(:size, options6)
        end.should raise_exception
      end

    end

    context :__validate_all__ do

      # All keys present in options
      options7 = {size: :long, with_pinyin: false}
      specify {TestClass.new.__validate_all__([:size, :with_pinyin], options7).should == {:size=>:long, :with_pinyin=>false} }

      # :with_pinyin present in options, :size not present in options (return with default value).
      options8 = {with_pinyin: false}
      specify {TestClass.new.__validate_all__([:size, :with_pinyin], options8).should == {:size=>:average, :with_pinyin=>false} }


      it "should throw an exception if a key value is invalid" do

        # :size is a supported key.
        # Key is present in options, but with an invalid key.
        # => Throw exception.
        options9 = {size: 'invalid'}
        lambda do
          TestClass.new.__validate_all__([:size, :with_pinyin], options9)
        end.should raise_exception
      end

    end


    context :validate_options_of do

      it "should throw an exception if a key is not supported" do

        options10 = {size: :average, not_supported: 'some_value'}

        lambda do
          TestClass.new.validate_options_of([:csv, :helper_method], options10)
        end.should raise_exception(ArgumentError, /not_supported/)
      end

      options11 = {size: :average, with_pinyin: false}
      specify { TestClass.new.validate_options_of([:csv, :helper_method], options11).should ==
                {:csv=>{}, :helper_method=>{:with_pinyin=>false, :size=>:average}} }

      # :size key not found in options, return default value
      options12 = {with_pinyin: false}
      specify { TestClass.new.validate_options_of([:csv, :helper_method], options12).should ==
                {:csv=>{}, :helper_method=>{:with_pinyin=>false, :size=>:average}} }

       it "should throw an exception if a value is not valid" do

        options13 = {size: 'invalid_value', with_pinyin: false}

        lambda do
          TestClass.new.validate_options_of([:csv, :helper_method], options13)
        end.should raise_exception(ArgumentError, /invalid_value/)
      end

    end


    context :is_boolean? do

      specify {TestClass.is_boolean?(true).should be_true }
      specify {TestClass.is_boolean?(false).should be_true }
      specify {TestClass.is_boolean?('true').should be_false }
    end
  end
end

