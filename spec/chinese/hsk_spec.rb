# encoding: utf-8

require 'spec_helper'

describe Chinese::HSK do

  let(:hsk) {described_class.new(1)}

  context :add_sentences_from do

    word_array   = CSV.read('spec/data/hsk_missing_words.csv', :encoding => 'utf - 8')
    raw_words    = Chinese::HSK.extract_column(word_array, 1)
    unique_words = Chinese::HSK.unique_words(raw_words).take(10)

    it "should download a sentence for every word" do

      sentences = hsk.add_sentences_from('http://www.jukuu.com/search.php?q={}', unique_words, '.c > td[2]', '.e > td[2]')
      p sentences
      # [["%E6%A5%9E", "他说，人们应该直楞楞地彼此看着对方。", "tā shuō ，rén men yìng gāi zhí léng léng dì bĭ cĭ kàn zhăo duì fāng 。",
      #   "He says men ought to look straight at one another."],
      #  ["%E9%A9%AE", "他真心狠, 让驴驮这么重的东西。", "tā zhēn xīn hĕn , ràng lǘ tuó zhè mo zhòng de dōng xī 。",
      #   "It is cruel of him to make the donkey carry such a heavy load."],
      #  ["%E9%A6%8B", "给我一些糖解解馋。", "gĕi wŏ yī xiē táng jiĕ jiĕ chán 。", "Give me a lot of candy for my sweet tooth."],
      #  ["%E8%A2%84", "我离开你的时候正好是春天,当绚烂的四月,披上新的锦袄,",
      #   "wŏ lí kāi nĭ de shí hòu zhèng hăo shì chūn tiān ,dāng xuàn làn de sì yuè ,pī shàng xīn de jĭn ăo ,",
      #   "From you have I been absent in the spring, When proud-pied April, dressed in all his trim,"],

    end
  end



  context :include_every_char? do


    words = ["我", "打", "他", "他们", "谁", "越 来越。。。"]

    sentences = [['我打他。', 'tag'],                #  我，打，他
                 ['他打我好疼。', 'tag'],            #  我，打，他
                 ['他打谁？', 'tag'],                #      打，他，谁
                 ['他们想知道你是谁。', 'tag'],      #              谁，他们
                 ['他们钱越来越多。', 'tag']]        #                  他们，越来越
    # ------------------------------------------------------------

    it "should work correctly" do

      hsk.include_every_char?("他们","他工作很忙").should be_false
      hsk.include_every_char?("越。。。 来越。。。","他工作很忙").should be_false
      hsk.include_every_char?("越。。。 来越。。。","他工作越来越忙").should be_true
    end

  end

  context "When running all necessary methods" do

    it "should return the minimum amount of sentences to cover all words" do

      words = Chinese::HSK.unique_words(words)

      with_target_words           = hsk.add_target_words_with_threads(sentences, words)
      sorted_by_unique_word_count = hsk.sort_by_unique_word_count(with_target_words)
      # sorted_with_tag             = hsk.add_word_count_tag(sorted_by_unique_word_count)
      sorted_with_tag             = hsk.add_word_list_and_count_tags(sorted_by_unique_word_count)
      minimum_sentences           = hsk.minimum_necessary_sentences(sorted_with_tag, words)
      # [[[["我", "打"], "我打他。"], "tag", "unique_2", "[我] [打]"],
      #  [[["谁"], "他打谁？"], "tag", "unique_2", "[打] [谁]"],
      #  [[["他们", "越 来越"], "他们钱越来越多。"], "tag", "unique_2", "[他们] [越 来越]"]]
      without_unique_word_arrays  = hsk.remove_words_array(minimum_sentences)
      # [["我打他。", "tag", "unique_2", "[我] [打]"],
      #  ["他打谁？", "tag", "unique_2", "[打] [谁]"],
      #  ["他们钱越来越多。", "tag", "unique_2", "[他们] [越 来越]"]]
      test_result                 = hsk.contains_all_unique_words?(without_unique_word_arrays, words)
      test_result.should be_true
    end
  end
end



