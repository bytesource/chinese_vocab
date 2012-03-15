# encoding: utf-8

require 'spec_helper'

# TODO:
# -- clean_words: split at chinese word boundary
#    handle parentheses
# -- design layout to be:
#    + easy to use
#    + handles missing words gracefully
# -- add method to add translation and pinyin to a word (no sentence)
# -- add method #unique_characters

describe Chinese::HSK do

  let(:hsk) {described_class.new(1)}

  context :add_sentences_from do

    word_array   = CSV.read('spec/data/hsk_missing_words.csv', :encoding => 'utf-8')
    raw_words    = Chinese::HSK.extract_column(word_array, 1)
    unique_words = Chinese::HSK.unique_words(raw_words).take(10) << "rohlfing"

    it "should download a sentence for every word" do

      # sentences = hsk.add_sentences(unique_words, :nciku)
      sentences = hsk.add_sentences(unique_words, :jukuu)
      p sentences
      hsk.not_found.should == ['rohlfing']
      # [["驮", "驮运曾在沙漠地区被广泛使用。", "tuó yùn céng zài shā mò dì qū bèi guăng fàn shĭ yòng 。",
      #   "Transferring goods by animals was once popular in the desert."],
      #   ["袄", "我扯了件夹袄披上，眼睛又定格在那厚厚的日记上。",
      #    "wŏ chĕ le jiàn jiá ăo pī shàng ，yăn jīng yòu dìng gé zài nă hòu hòu de rì jì shàng 。",
      #    "I grabbed a lined jacket and put it on, then went on with my reading of the diary."],
      #   ["捌", "", "", ""],
      #   ["蹬", "一世蹭蹬使他看透了人间世态。", "yī shì cèng dèng shĭ tā kàn tòu le rén jiàn shì tài 。",
      #    "Countless frustrations all his life made him see the ways of the world."],
      #    ["楞", "这个楞场堆满了木材，一点多余的空间都没有了。",
      #     "zhè gè léng cháng duī măn le mù cái ，yī diăn duō yú de kōng jiàn dōu méi yŏu le 。",
      #     "The relay place is stacked with lumber, sparing no room ."],
      #    ["蝉", "蝉衣可以入药。", "chán yī kĕ yĭ rù yào 。", "Cicada sloughs can be made into medicines."],
      #    ["馋", "这孩子真是个馋鬼。", "zhè hái zi zhēn shì gè chán guĭ 。", "Indeed, this child is a glutton."],
      #    ["疮", "跟歹徒搏斗时他受伤了，之后感染了棒疮。", "gēn dăi tú bó dòu shí tā shòu shāng le ，zhī hòu găn răn le bàng chuāng 。
      #     ", "He was injured in a fight with a gangster, and then got an infection from the wounds of the heavy beating."],
      #    ["讹", "以讹传讹造成的悲剧真是太多了。", "yĭ é chuán é zào chéng de bēi jù zhēn shì tài duō le 。",
      #     "There are really a great many tragedies caused by spreading false news."],
      #    ["贰", "贰臣", "èr chén", "Previous"],
      #    ["rohlfing", "", "", ""]]

    end
  end


  describe "Testing locally without fetching data from the web" do

    sample_words = ["我", "打", "他", "他们", "谁", "越 来越。。。"]

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

        words = Chinese::HSK.unique_words(sample_words)

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
end



