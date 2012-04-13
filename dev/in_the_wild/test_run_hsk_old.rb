# encoding: utf-8

require 'chinese'

words = Chinese::Vocab.parse_words('../../hsk_data/word_lists/old_hsk_level_8828_chars_1_word_edited.csv', 4)
p words.take(6)

anki = Chinese::Vocab.new(words, :compact => true)

all_words = anki.words
p all_words.take(6)
puts "Number of distinct words: #{all_words.size}"

File.open('all_words_edited', 'w') do |f|
  f.puts all_words
end
puts "Saved edited words to file."

sentences = anki.min_sentences(:size => :short, :source => :nciku, :with_pinyin => true, :thread_count => 8)
anki.to_csv('in_the_wild_test.csv')
puts "Contains all words?: #{anki.contains_all_target_words?(sentences, :chinese)}."
puts "Missing words (@not_found): #{anki.not_found}"
puts "Number of unique characters in sentences: #{anki.sentences_unique_chars.size}"

