# encoding: utf-8

require 'spec_helper'

describe Chinese::HSK do
  let(:hsk) {described_class.new(1)}

  words = ["我", "打", "他", "他们", "谁", "越 来越。。。"]

  sentences = [['我打他。', 'tag'],                #  我，打，他
               ['他打我好疼。', 'tag'],            #  我，打，他
               ['他打谁？', 'tag'],                #      打，他，谁
               ['他们想知道你是谁。', 'tag'],      #              谁，他们
               ['他们钱越来越多。', 'tag']]        #                  他们，越来越
  # ------------------------------------------------------------

  context :include_every_char? do

    it "should work correctly" do

      hsk.include_every_char?("他们","他工作很忙").should be_false
      hsk.include_every_char?("越。。。 来越。。。","他工作很忙").should be_false
      hsk.include_every_char?("越。。。 来越。。。","他工作越来越忙").should be_true
    end

  end

  context "When running all necessary methods" do

    it "should return the minimum amount of sentences to cover all words" do

      words = Chinese::HSK.unique_words(words)

      with_target_words           = hsk.add_target_words(sentences, words)
      sorted_by_unique_word_count = hsk.sort_by_unique_word_count(with_target_words)
      sorted_with_tag             = hsk.add_word_count_tag(sorted_by_unique_word_count)
      minimum_sentences           = hsk.minimum_necessary_sentences(sorted_with_tag, words)
      # [[[["我", "打"], "我打他。"], "tag", "unique_2"],
      #  [[["谁"], "他打谁？"], "tag", "unique_2"],
      #  [[["他们", "越 来越"], "他们钱越来越多。"], "tag", "unique_2"]]
      without_unique_word_arrays  = hsk.remove_words_array(minimum_sentences)
      # [["我打他。", "tag", "unique_2"],
      #  ["他打谁？", "tag", "unique_2"],
      #  ["他们钱越来越多。", "tag", "unique_2"]]
      test_result                 = hsk.contains_all_unique_words?(without_unique_word_arrays, words)
      test_result.should be_true
    end
  end
end



