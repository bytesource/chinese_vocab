# encoding: utf-8

require 'spec_helper'

describe Chinese::Vocab do
  include HelperMethods

  let(:vocab) {described_class.new(1)}


  context "When running all necessary methods" do

    it "should return the minimum amount of sentences to cover all words" do

      t = time do
        unique_words_source = CSV.read('spec/data/vocab_unique_words_source_EDITED.csv', :encoding => 'utf-8', :col_sep => '|')
        word_col            = Chinese::Vocab.extract_column(unique_words_source, 4)
        unique_words        = Chinese::Vocab.unique_words(word_col)
        puts "Unique words count = #{unique_words.size}."

        data = CSV.read('spec/data/vocab_20000_chin_engl_pinyin.csv', :encoding => 'utf-8', :col_sep => '|')
        puts "data size: #{data.size}"

        vocab = Chinese::Vocab.new(1)
        with_target_words           = vocab.add_target_words(data, unique_words)
        puts "with target words: #{with_target_words.size}"
        sorted_by_unique_word_count = vocab.sort_by_unique_word_count(with_target_words)
        puts "sorted by unique word count: #{sorted_by_unique_word_count.size}"
        # sorted_with_tag             = vocab.add_word_count_tag(sorted_by_unique_word_count)
        sorted_with_tag             = vocab.add_word_list_and_count_tags(sorted_by_unique_word_count)
        puts "sorted with tag: #{sorted_with_tag.size}"
        minimum_sentences           = vocab.minimum_necessary_sentences(sorted_with_tag, unique_words)
        puts "minimum sentences: #{minimum_sentences.size}"
        without_unique_word_arrays  = vocab.remove_words_array(minimum_sentences)
        puts "without unique word arrays: #{without_unique_word_arrays.size}"
        vocab.to_file('spec/data/output/vocab_traditional_min_sentences.txt', without_unique_word_arrays, :col_sep => '|')

        test_result = vocab.contains_all_unique_words?(without_unique_word_arrays, unique_words)
        puts "after last test: #{without_unique_word_arrays.size}"
        test_result.should be_true
      end
      puts "Minutes passed: #{t/60}."
    end
  end
end


