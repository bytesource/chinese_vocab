# encoding: utf-8
require 'spec_helper'

describe Chinese::Vocab do

  context :full_run do
    words = Chinese::Vocab.parse_words('../../hsk_data/word_lists/old_hsk_level_8828_chars.csv', 4)

    anki = Chinese::Vocab.new(words, :compress => true)

    File.open('all_words_edited', 'w') do |f|
      f.puts anki.words
    end
    puts "Saved edited words to file."

    sentences = anki.min_sentences(:size => :small, :source => :nciku, :with_pinyin => true)
    anki.to_csv('in_the_wild_test.csv')
    puts "Contains all words?: #{anki.contains_all_target_words?(sentences, :chinese)}."
    puts "Missing words: #{anki.not_found}"
    puts "Number of unique characters in sentences: #{anki.sentences_unique_chars}"
  end

end
