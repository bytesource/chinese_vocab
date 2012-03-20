# encoding: utf-8

puts "Real run"
puts "================================"

def time (&block)
  start = Time.now
  block.call if block
  stop = Time.now
  total = stop-start
  puts "================================="
  puts "Total time passed: #{total}."
end

time {
  unique_words_source = CSV.read('./data/vocab_unique_words_source.csv', :encoding => 'utf-8', :col_sep => ',')
  word_col            = Chinese::Vocab.extract_column(unique_words_source, 4)
  unique_words        = Chinese::Vocab.unique_words(word_col)

  data = CSV.read('./data/vocab_20000_chin_engl_pinyin.csv', :encoding => 'utf-8', :col_sep => '|')

  vocab = Chinese::Vocab.new(1)

  with_target_words           = vocab.add_target_words_with_threads(data, unique_words)
  sorted_by_unique_word_count = vocab.sort_by_unique_word_count(with_target_words)
  sorted_with_tag             = vocab.add_word_count_tag(sorted_by_unique_word_count)
  minimum_sentences           = vocab.minimum_necessary_sentences(sorted_with_tag, words)
  without_unique_word_arrays  = vocab.remove_words_array(minimum_sentences)
  vocab.to_file('vocab_20000_min_sentences.txt', without_unique_word_arrays, :col_sep => '|')


  test_result = new_vocab.contains_all_unique_words?(without_unique_word_arrays, words)
  puts "Contains all unique words? => #{test_result}."
}


