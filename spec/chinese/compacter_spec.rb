# encoding: utf-8

require 'spec_helper'

describe Chinese::Compacter do

  words = ["我", "打", "他", "他们", "谁", "越 。。。 来越", "除了。。。 以为。。。"]

  sentences = [['我打他。'],
               ['他打我好疼。'],
               ['他打谁？'],
               ['他们想知道你是谁。'],
               ['他们钱越来越多。'],
               ['除了饺子以外，我也很喜欢吃馒头'],
               ['除了饺子之外，我也很喜欢吃馒头']]

  context "On success" do

    let(:compacter) {described_class.new}

    context :split_word do

    end

    context :include_every_char? do



      # word: "越 来越", sentence: '他们钱越来越多。'
      specify { compacter.include_every_char?(words[5], sentences[4]).should be_true }

    end
  end
end




