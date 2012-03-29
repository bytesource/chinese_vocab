# encoding: utf-8

require 'spec_helper'

describe Chinese::Vocab do

  # NOTE:  "浮鞋" is only found on jukuu.
  words = ["我", "打", "他", "他们", "谁", "越 。。。 来越", "除了。。。 以外。。。", "浮鞋"]

  sentences = ['我打他。',
               '他打我好疼。',
               '他打谁？',
               '他们想知道你是谁。',
               '他们钱越来越多。',
               '除了饺子以外，我也很喜欢吃馒头',
               '除了饺子之外，我也很喜欢吃馒头']


  context "Instance methods" do
    let(:vocab) {described_class.new(words)}


    context :to_csv do

      specify do
        puts "all words: #{vocab.words}."
        min = vocab.min_sentences
        to_file = vocab.to_csv('test_file')
        from_file = CSV.read('test_file', :encoding => 'utf-8')
        from_file.should == to_file.map {|row| row.values }
        vocab.contains_all_target_words?(min, :chinese).should be_true
      end
    end
  end
end

