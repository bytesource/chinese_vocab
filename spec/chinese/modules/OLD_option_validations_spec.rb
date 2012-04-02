# encoding: utf-8

require 'spec_helper'

describe Chinese::OptionValidations do

  let(:mod)     { described_class }
  let(:methods) { mod.instance_methods(false) }



  context "Inspecting methods" do

    specify { methods.should ==
              [:__object__, :validate_value, :validate_keys, :__option_keys__,
               :is_boolean?, :is_unicode?, :distinct_words] }


  end

  context "When including the module" do

      class WithOptions
        include Chinese::OptionValidations

        Options = {:source =>  [lambda {|value| is_boolean?(value) },[:method1, :method3]],
                   :other =>   [lambda {|value| ['hello', 'world'].include?(value) }, [:method1, :method2]]}

        def test_options(options={})
          validate_keys(options)
        end

      end

    it "should add its methods as instance methods of the class" do

      methods.each do |m|
        WithOptions.new.respond_to?(m).should be_true
      end
    end

    it "should add its methods as singleton methods of the class" do

      methods.each do |m|
        WithOptions.respond_to?(m).should be_true
      end
    end


    context :is_boolean? do

      specify {WithOptions.is_boolean?(true).should be_true }
      specify {WithOptions.is_boolean?(false).should be_true }
      specify {WithOptions.is_boolean?('true').should be_false }
    end


    context :__options_keys__ do


      specify {WithOptions.__option_keys__(:method1, WithOptions::Options).should == [:source, :other] }
    end


    context :validate_keys do

      correct_ops    = {:source => 1, :other => 2}
      with_wrong_ops = {:source => 1, :other => 2, :wrong => 3}

      specify {WithOptions.new.test_options(correct_ops).should == nil }

      it "should throw an exception if a wrong option key is passed to a method" do

        lambda do
          WithOptions.new.test_options(with_wrong_ops)
        end.should raise_exception
      end
    end

    context :validate_value do


      let(:options)   { {:source => false, :other => 'hello'} }
      let(:ops_other) { [{:other => 'not_defined'}, # Value not valid. Should raise exception
                         {}] }                      # Key not present. Should return default value for key.

      let(:defaults) { [false, 'hello', 'default'] }

      # 'validate' as singleton method
      specify { WithOptions.validate_value(options, :source, WithOptions::Options, defaults[0]).should be_false }
      # Options constant is optional
      specify { WithOptions.validate_value(options, :other , defaults[1]).should == 'hello' }
      specify { lambda do WithOptions.validate(ops_other[0], :other , defaults[1]) end.should raise_exception }
      specify { WithOptions.validate_value(ops_other[1], :other , defaults[2]).should == 'default' }
      # 'validate' as instance method
      specify { WithOptions.new.validate_value(options, :source, WithOptions::Options, defaults[0]).should be_false }
      # Options constant is optional
      specify { WithOptions.new.validate_value(options, :other , defaults[1]).should == 'hello' }
      specify { lambda do WithOptions.new.validate(ops_other[0], :other , defaults[1]) end.should raise_exception }
      specify { WithOptions.new.validate_value(ops_other[1], :other , defaults[2]).should == 'default' }
    end
  end
end
