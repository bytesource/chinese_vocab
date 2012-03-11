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
  unique_words_source = CSV.read('./data/hsk_unique_words_source.csv', :encoding => 'utf-8', :col_sep => ',')
  word_col            = Chinese::HSK.extract_column(unique_words_source, 4)
  unique_words        = Chinese::HSK.unique_words(word_col)

  data = CSV.read('./data/hsk_20000_chin_engl_pinyin.csv', :encoding => 'utf-8', :col_sep => '|')

  hsk = Chinese::HSK.new(1)

  with_target_words           = hsk.add_target_words_with_threads(data, unique_words)
  sorted_by_unique_word_count = hsk.sort_by_unique_word_count(with_target_words)
  sorted_with_tag             = hsk.add_word_count_tag(sorted_by_unique_word_count)
  minimum_sentences           = hsk.minimum_necessary_sentences(sorted_with_tag, words)
  without_unique_word_arrays  = hsk.remove_words_array(minimum_sentences)
  hsk.to_file('hsk_20000_min_sentences.txt', without_unique_word_arrays, :col_sep => '|')


  test_result = new_hsk.contains_all_unique_words?(without_unique_word_arrays, words)
  puts "Contains all unique words? => #{test_result}."
}


