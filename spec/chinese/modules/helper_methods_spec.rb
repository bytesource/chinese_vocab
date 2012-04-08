# encoding: utf-8

require 'spec_helper'

describe Chinese::HelperMethods do

  class TestClass
    include Chinese::HelperMethods
  end


  context :distinct_words do
    words = ["我", "打", "他", "他们", "谁", "越 。。。 来越", "除了。。。 以外。。。", "浮鞋"]

    specify { TestClass.new.distinct_words(words[5]).should == ["越", "来越"] }
    specify { TestClass.new.distinct_words(words[6]).should == ["除了", "以外"] }

    specify { TestClass.distinct_words(words[5]).should == ["越", "来越"] }
    specify { TestClass.distinct_words(words[6]).should == ["除了", "以外"] }

  end


  context :is_unicode? do

    ascii   = ["hello, ....", "This is perfect!"]
    chinese = ["U盘", "X光", "周易衡"]

    specify { ascii.all? {|word| TestClass.new.is_unicode?(word) }.should be_false }
    specify { chinese.all? {|word| TestClass.new.is_unicode?(word) }.should be_true }

    specify { ascii.all? {|word| TestClass.is_unicode?(word) }.should be_false }
    specify { chinese.all? {|word| TestClass.is_unicode?(word) }.should be_true }
  end
end
