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

    context :new_make_hash do
      obj1 = described_class.new(["豆浆"])
      obj2 = described_class.new(["豆浆"])
      obj1.id.should == obj2.id

      obj4 = described_class.new(["豆浆"], :compress => true)
      obj5 = described_class.new(["豆浆"], :compress => true)
      obj4.id.should == obj5.id

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

    context :select_sentence do

      # Word not found online
      specify do
        vocab.select_sentence("罗飞科", {}).should be_nil
        vocab.not_found.include?("罗飞科").should be_true
      end
      specify do
        vocab.select_sentence("浮鞋", {}).should == {:word=>"浮鞋", :chinese=>"舌型浮鞋", :english=>"flapper float shoe"}
        vocab.not_found.include?("浮鞋").should be_false
        # vocab.with_pinyin  # is always nil because @with_pinyin gets set in #senteces,
        # but here #select sentence is called in isolation.
      end
    end

    context :sentences do

      word_list = ["浮鞋"]
      let(:new_vocab) { described_class.new(word_list) }

      it "should scrap the sentence from the second download source if a word
      was not found on the first one" do

        # "浮鞋" is not found on the default download source (:nciku),
        # but returns a result on the second one (:jukuu).
        # Therefore the following must not return an empty array:
        new_vocab.sentences.should ==
          [{:word=>"浮鞋", :chinese=>"舌型浮鞋", :pinyin=>"shé xíng fú xié", :english=>"flapper float shoe"}]
        # [["除了 以外", "除了这张大钞以外，我没有其他零票了。",
        #   "chú le zhè zhāng dà chāo yĭ wài ，wŏ méi yŏu qí tā líng piào le
        #   "I have no change except for this high denomination banknote."]]
      end

      specify do
        new_vocab.sentences.all? {|hash| hash.has_key?(:pinyin)}.should be_true
        new_vocab.with_pinyin.should be_true
      end
      specify {new_vocab.sentences(:with_pinyin => true).all? {|hash| hash.has_key?(:pinyin)}.should be_true }
      specify do
        new_vocab.sentences(:with_pinyin => false).any? {|hash| hash.has_key?(:pinyin)}.should be_false
        new_vocab.with_pinyin.should be_false
      end

      # @stored_sentences should be set to the result of this method.
      specify {new_vocab.sentences.should == new_vocab.stored_sentences }

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

    context :target_words_per_sentence do
      sentence     = '除了饺子以外，我也很喜欢吃馒头'
      target_words = ["我们","除了 以外","我","你","喜欢"]

      specify { vocab.target_words_per_sentence(sentence, target_words).should == ["除了 以外", "我", "喜欢"] }
    end

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
      # Replaced each English and pinyin sententence with an empty string to make the output more readable:
      # [{:word=>"谁", :chinese=>"后来他们谁也不理谁。", :pinyin=>"", :english=>"", :target_words=>["谁", "他们"]},
      #  {:word=>"打", :chinese=>"我跟他是八竿子打不着的亲戚。", :pinyin=>"", :english=>"", :target_words=>["我", "打"]},
      #  {:word=>"除了 以外", :chinese=>"除了这张大钞以外，我没有其他零票了。", :pinyin=>"", :english=>"", :target_words=>["我", "除了 以外"]},
      #  {:word=>"浮鞋", :chinese=>"舌型浮鞋", :pinyin=>"", :english=>"", :target_words=>["浮鞋"]},
      #  {:word=>"他们", :chinese=>"他们正忙着装修爱巢呢！", :pinyin=>"", :english=>"", :target_words=>["他们"]},
      #  {:word=>"越 来越", :chinese=>"出口秀节目越来越受欢迎。", :pinyin=>"", :english=>"", :target_words=>["越 来越"]},
      #  {:word=>"我", :chinese=>"我们两家是世交，他比我大，是我的世兄。", :pinyin=>"", :english=>"", :target_words=>["我"]}]
      specify { obj.select_minimum_necessary_sentences(s).size.should < s.size }

      minimum_necessary_sentences = obj.select_minimum_necessary_sentences(s)
      specify { obj.contains_all_target_words?(minimum_necessary_sentences, :chinese).should be_true }
      # Replaced each English and pinyin sententence with an empty string to make the output more readable:
      # [{:word=>"谁", :chinese=>"后来他们谁也不理谁。", :pinyin=>"", :english=>"", :target_words=>["谁", "他们"]},
      #  {:word=>"打", :chinese=>"我跟他是八竿子打不着的亲戚。", :pinyin=>"", :english=>"", :target_words=>["我", "打"]},
      #  {:word=>"除了 以外", :chinese=>"除了这张大钞以外，我没有其他零票了。", :pinyin=>"", :english=>"", :target_words=>["我", "除了 以外"]},
      #  {:word=>"浮鞋", :chinese=>"舌型浮鞋", :pinyin=>"", :english=>"", :target_words=>["浮鞋"]},
      #  {:word=>"越 来越", :chinese=>"出口秀节目越来越受欢迎。", :pinyin=>"", :english=>"", :target_words=>["越 来越"]}]

    end

    context :remove_keys do

      hash1       = {a: 1, b: 2, c: 3, d: 4}
      hash2       = {a: 1, b: 2, c: 3, d: 4, e: 5}
      hash_array = [hash1, hash2]

      specify { vocab.remove_keys(hash_array, :a, :b).should == [{:c=>3, :d=>4}, {:c=>3, :d=>4, :e=>5}] }
      # If the key to be removed is not present in the hash, the input and output should be the same:
      specify { vocab.remove_keys(hash_array, :e).should == [{a: 1, b: 2, c: 3, d: 4}, {a: 1, b: 2, c: 3, d: 4}] }
    end

    context :add_key do
      hash1       = {a: '123456', b: [1, 2, 3, 4]}
      hash2       = {a: '1234', b: [1, 2, 3, 4]}
      hash_array = [hash1, hash2]

      specify {vocab.add_key(hash_array, :size) {|row| row[:a].length }.should ==
               [{:a=>"123456", :b=>[1, 2, 3, 4], :size=>6}, {:a=>"1234", :b=>[1, 2, 3, 4], :size=>4}] }
      # Without specifiying a block, the input and output should be the same:
      specify {vocab.add_key(hash_array, :size).should == hash_array }

    end

    context :uwc_tag do

      specify {vocab.uwc_tag("123").should == "3_words" }
      specify {vocab.uwc_tag("12345").should == "5_words" }
      specify {vocab.uwc_tag("1").should == "1_word" }
    end

    context :min_sentences do

      specify do
        vocab.min_sentences.size.should < vocab.sentences.size
        vocab.not_found.should be_empty
      end
      # Replaced each English and pinyin sententence with an empty string to make the output more readable:
      # [{:chinese=>"后来他们谁也不理谁。", :pinyin=>"", :english=>"", :uwc=>"3_words", :uws=>"他, 他们, 谁"},
      #  {:chinese=>"我跟他是八竿子打不着的亲戚。", :pinyin=>"", :english=>"", :uwc=>"3_words", :uws=>"我, 打, 他"},
      #  {:chinese=>"除了这张大钞以外，我没有其他零票了。", :pinyin=>"", :english=>"", :uwc=>"3_words", :uws=>"我, 他, 除了 以外"},
      #  {:chinese=>"舌型浮鞋", :pinyin=>"", :english=>"", :uwc=>"1_word", :uws=>"浮鞋"},
      #  {:chinese=>"出口秀节目越来越受欢迎。", :pinyin=>"", :english=>"", :uwc=>"1_word", :uws=>"越 来越"}]
      specify {vocab.contains_all_target_words?(vocab.min_sentences, :chinese).should be_true }

      # "罗飞科" cannot be found online.
      new_vocab = described_class.new(["罗飞科"])
      specify do
        new_vocab.min_sentences.should be_empty
        new_vocab.not_found.should == ["罗飞科"]
      end

      # @stored_sentences should be set to the result of this method.
      specify { new_vocab.min_sentences.should == new_vocab.stored_sentences }

    end

    context :sentences_unique_chars do
      my_sentences = ["我们跟他们是好朋友。","我们跟他们是好朋友。"]

      specify { vocab.sentences_unique_chars(my_sentences).should == ["我", "们", "跟", "他", "是", "好", "朋", "友"] }
      # Without an argument uses @stored_sentences as input.
      specify do
        # Create a stub:
        vocab.stub(:stored_sentences) { ["我们跟他们是好朋友。","你你你你你你"] }
        vocab.sentences_unique_chars.should == ["我", "们", "跟", "他", "是", "好", "朋", "友", "你"]
      end
    end

    context :to_csv do

      specify do
        min = vocab.min_sentences
        to_file = vocab.to_csv('test_file')
        from_file = CSV.read('test_file', :encoding => 'utf-8')
        from_file.should == to_file.map {|row| row.values }
      end
    end
  end
end




