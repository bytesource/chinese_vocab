# encoding: utf-8

require 'spec_helper'

describe Chinese::Options do
  include Chinese::Options  # Include here so we can use this module's #is_boolean? below

  let(:mod)     { described_class }
  let(:methods) { mod.instance_methods(false) }

  context "Inspecting methods" do

    specify { methods.should == [:validate, :is_boolean?] }


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

        options           = {:source => false, :other => 'hello'}  #
        validation_source = lambda {|value| is_boolean?(value) }  # is_boolean? can be used because we included the module above.
        options_other2    = {:other => 'not_defined'}    # Value not valid. Should raise exception
        options_other3    = {}                           # key not present. Should return default value for key.
        validation_other  = lambda {|value| ['hello', 'world'].include?(value) }
        default_source    = true
        default_other     = 'default'

        specify { test_class.validate(:source, options, validation_source, default_source).should be_false }
        specify { test_class.validate(:other , options, validation_other , default_other).should == 'hello' }
        specify { lambda do test_class.validate(:other , options_other2, validation_other, default_other) end.should raise_exception }
        specify { test_class.validate(:other , options_other3, validation_other, default_other).should == 'default' }
    end
  end
end
