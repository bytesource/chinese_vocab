# encoding: utf-8
require 'spec_helper'

describe Chinese::Vocab do

  context :full_run do
    words = Chinese::Vocab.parse_words('../../hsk_data/word_lists/old_hsk_level_8828_chars.csv', 4)

    anki = Chinese::Vocab.new(words, :compress => true)

    sentences = anki.min_sentences
    puts "Contains all words?: #{anki.contains_all_target_words?(sentences)}."
    anki.to_csv('in_the_wild_test.csv')
  end

end
