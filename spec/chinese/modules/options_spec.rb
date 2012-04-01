# encoding: utf-8

require 'spec_helper'

describe Chinese::Options do
  include Chinese::Options  # Include here so we can use this module's #is_boolean? below

  let(:mod)     { described_class }
  let(:methods) { mod.instance_methods(false) }

  context "Inspecting methods" do

    specify { methods.should == [:__validation_constant__, :validate, :is_boolean?, :is_unicode?, :distinct_words] }


  end

  context "When including the module" do

    let(:test_class) do
      class WithOptions
        include Chinese::Options
      end
    end

    it "should add its methods as intance methods of the class" do

      methods.each do |m|
        test_class.new.respond_to?(m).should be_true
      end
    end

    it "should add its methods as singleton methods of the class" do

      methods.each do |m|
        test_class.respond_to?(m).should be_true
      end
    end


    context :is_boolean? do

      specify {test_class.is_boolean?(true).should be_true }
      specify {test_class.is_boolean?(false).should be_true }
      specify {test_class.is_boolean?('true').should be_false }
    end

    context :validate do
                                        # is_boolean? can be called because we included the module above.
      Validations = {source: lambda {|value| is_boolean?(value) },
                     other:  lambda {|value| ['hello', 'world'].include?(value) }}


      let(:options)   { {:source => false, :other => 'hello'} }
      let(:ops_other) { [{:other => 'not_defined'}, # Value not valid. Should raise exception
                           {}] }                      # Key not present. Should return default value for key.

      let(:defaults) { [false, 'hello', 'default'] }

      # 'validate' as singleton method
      specify { test_class.validate(options, :source, defaults[0]).should be_false }
      specify { test_class.validate(options, :other , Validations[:other] , defaults[1]).should == 'hello' }
      specify { lambda do test_class.validate(ops_other[0], :other , Validations[:other], defaults[1]) end.should raise_exception }
      specify { test_class.validate(ops_other[1], :other , Validations[:other], defaults[2]).should == 'default' }
      # 'validate' as instance method
      specify { test_class.new.validate(options, :source, defaults[0]).should be_false }
      specify { test_class.new.validate(options, :other , Validations[:other] , defaults[1]).should == 'hello' }
      specify { lambda do test_class.new.validate(ops_other[0], :other , Validations[:other], defaults[1]) end.should raise_exception }
      specify { test_class.new.validate(ops_other[1], :other , Validations[:other], defaults[2]).should == 'default' }
    end
  end
end
