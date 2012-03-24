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

  context "Class methods" do

    # data/old_hsk_short.csv:
    # "4","3571","座右銘","座右铭","zuòyòumíng","motto","n"
    # ,,,,,,                                                      => no data
    #   "4","3571","座右銘","座右铭","zuòyòumíng","motto","n"
    #                                                             => blank line
    # "4","3571","座右銘","","zuòyòumíng","motto","n"             => word column is an empty string
    # "4","3571","座右銘","    ","zuòyòumíng","motto","n"         => word column only contains whitespace
    # "4","3571","座右銘",,"zuòyòumíng","motto","n"               => word column contains no data
    # ,,,,,,

    let(:vocab) {described_class}

    context :words do

      specify {vocab.parse_words('data/old_hsk_short.csv', 4).should == ["座右铭", "座右铭"] }
    end

    context :within_range? do

      row = [:a, :b, :c, :d, :e] # 5 columns

      specify {vocab.within_range?(1, row).should be_true }
      specify {vocab.within_range?(3, row).should be_true }
      specify {vocab.within_range?(5, row).should be_true }
      specify {vocab.within_range?(6, row).should be_false }
    end
  end

  context "Instance methods" do
    let(:vocab) {described_class.new(words)}

    context :remove_redundant_single_char_words do

      edited_words = ["看书", "玩球","看","书","玩","球"]

      specify { vocab.remove_redundant_single_char_words(edited_words).should == ["看书", "玩球"] }
    end

    context :remove_parens do

      # Using ASCII parens
      specify {vocab.remove_parens("除了。。以外(之外)").should == "除了。。以外" }
      # Using Chinese parens
      specify {vocab.remove_parens("除了。。。以外（之外）").should == "除了。。。以外" }
    end

    context :edit_vocab do

      passed_to_initialize = ["除了。。以外(之外)", "除了。。。以外（之外）", "U盘", "U盘"]

      # Edit and remove duplicates
      specify {vocab.edit_vocab(passed_to_initialize).should == ["除了 以外", "U盘"] }
    end

    context :sentences do

      word_list = ["浮鞋"]
      let(:new_vocab) { described_class.new(word_list) }

      it "should scrap the sentence from the second download source if a word
      was not found on the first one" do

        # "浮鞋" is not found on the default download source (:nciku),
        # but returns a result on the second one (:jukuu).
        # Therefore the following must not return an empty array:
        new_vocab.sentences(:with_pinyin => true).should ==
          [{:word=>"浮鞋", :chinese=>"舌型浮鞋", :pinyin=>"shé xíng fú xié", :english=>"flapper float shoe"}]
        # [["除了 以外", "除了这张大钞以外，我没有其他零票了。",
        #   "chú le zhè zhāng dà chāo yĭ wài ，wŏ méi yŏu qí tā líng piào le
        #   "I have no change except for this high denomination banknote."]]
      end
    end


    context :alternate_source do

      specify {vocab.alternate_source([:a, :b], :b).should == :a }
      specify {vocab.alternate_source([:a, :b], :a).should == :b }
    end

    context :is_unicode? do

      ascii   = ["hello, ....", "This is perfect!"]
      chinese = ["U盘", "X光", "周易衡"]

      specify { ascii.all? {|word| vocab.is_unicode?(word) }.should be_false }
      specify { chinese.all? {|word| vocab.is_unicode?(word) }.should be_true }

    end

    context :distinct_words do

      specify { vocab.distinct_words(words[5]).should == ["越", "来越"] }
      specify { vocab.distinct_words(words[6]).should == ["除了", "以外"] }

    end

    context :include_every_char? do

      # word: "越 来越", sentence: '他们钱越来越多。'
      specify { vocab.include_every_char?(words[5], sentences[4]).should be_true }

    end

    # context :target_words_per_sentence do
    #   sentence     = '除了饺子以外，我也很喜欢吃馒头'
    #   target_words = ["我们","除了 以外","我","你","喜欢"]

    #   specify { vocab.target_words_per_sentence(sentence, target_words).should == ["除了 以外", "我", "喜欢"] }
    # end

    context :add_target_words do

      # @words = ["我", "打", "他", "他们", "谁", "越 来越", "除了 以外", "浮鞋"]

      hash_array = [{word: "_", chinese: '除了饺子以外，我也很喜欢吃馒头', pinyin: '_', english: '_'},
                    {word: "_", chinese: '钻井需要用浮鞋', pinyin: '_', english: '_'}]

      specify { target_words = vocab.add_target_words(hash_array).map {|hash| hash[:target_words] }.
                array_of_arrays_equal?([["除了 以外", "我"],["浮鞋"]]) }
    end

    context :sort_by_target_word_count do

      with_target_words = [{word: "_", chinese: '1', pinyin: '_', english: '_', target_words: [1,2,3]},
                           {word: "_", chinese: '12', pinyin: '_', english: '_', target_words: [1,2,3]},
                           {word: "_", chinese: '123', pinyin: '_', english: '_', target_words: [1,2]},
                           {word: "_", chinese: '1234', pinyin: '_', english: '_', target_words: [1,2]},
                           {word: "_", chinese: '123456', pinyin: '_', english: '_', target_words: [1,2,3,4]} ]


      specify { vocab.sort_by_target_word_count(with_target_words).should ==
                [{word: "_", chinese: '123456', pinyin: '_', english: '_', target_words: [1,2,3,4]},
                 {word: "_", chinese: '1', pinyin: '_', english: '_', target_words: [1,2,3]},
                 {word: "_", chinese: '12', pinyin: '_', english: '_', target_words: [1,2,3]},
                 {word: "_", chinese: '123', pinyin: '_', english: '_', target_words: [1,2]},
                 {word: "_", chinese: '1234', pinyin: '_', english: '_', target_words: [1,2]}] }

    end

    context :contains_all_target_words? do

      obj  = described_class.new(["除了。。。以外", "浮鞋", "我们"])
      arr1 =  [{word: "_", chinese: '除了饺子以外，我也很喜欢吃馒头', pinyin: '_', english: '_', target_words: []},
               {word: "_", chinese: '我们不怕冷', pinyin: '_', english: '_', target_words: []} ]
      arr2 = arr1.dup << {word: "_", chinese: '钻井需要用浮鞋', pinyin: '_', english: '_', target_words: []}


      specify { obj.contains_all_target_words?(arr1, :chinese).should be_false }
      specify { obj.contains_all_target_words?(arr2, :chinese).should be_true }
    end

    context :select_minimum_necessary_sentences do

      obj = described_class.new(words, :compress => true)
      s = obj.sentences
      with_target_words = obj.add_target_words(s)
      sorted_by_target_word_count = obj.sort_by_target_word_count(with_target_words)
    # [{:word=>"谁", :chinese=>"后来他们谁也不理谁。", :english=>"", :target_words=>["谁", "他们"]},
    #  {:word=>"打", :chinese=>"我跟他是八竿子打不着的亲戚。", :english=>"", :target_words=>["我", "打"]},
    #  {:word=>"除了 以外", :chinese=>"除了这张大钞以外，我没有其他零票了。", :english=>"", :target_words=>["我", "除了 以外"]},
    #  {:word=>"浮鞋", :chinese=>"舌型浮鞋", :english=>"", :target_words=>["浮鞋"]},
    #  {:word=>"他们", :chinese=>"他们正忙着装修爱巢呢！", :english=>"", :target_words=>["他们"]},
    #  {:word=>"越 来越", :chinese=>"出口秀节目越来越受欢迎。", :english=>"", :target_words=>["越 来越"]},
    #  {:word=>"我", :chinese=>"我们两家是世交，他比我大，是我的世兄。", :english=>"", :target_words=>["我"]}]

      specify { obj.select_minimum_necessary_sentences(s).size.should < s.size }

      minimum_necessary_sentences = obj.select_minimum_necessary_sentences(s)
      specify { obj.contains_all_target_words?(minimum_necessary_sentences, :chinese).should be_true }
      # [{:word=>"谁", :chinese=>"后来他们谁也不理谁。", :english=>"", :target_words=>["谁", "他们"]},
      #  {:word=>"打", :chinese=>"我跟他是八竿子打不着的亲戚。", :english=>"", :target_words=>["我", "打"]},
      #  {:word=>"除了 以外", :chinese=>"除了这张大钞以外，我没有其他零票了。", :english=>"", :target_words=>["我", "除了 以外"]},
      #  {:word=>"浮鞋", :chinese=>"舌型浮鞋", :english=>"", :target_words=>["浮鞋"]},
      #  {:word=>"越 来越", :chinese=>"出口秀节目越来越受欢迎。", :english=>"", :target_words=>["越 来越"]}]

    end
  end
end




