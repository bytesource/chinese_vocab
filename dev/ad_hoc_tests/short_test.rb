# encoding: utf-8
require '../../lib/chinese'

# ------------------------------------------------------------
puts "Starting testing..."
puts

words = ["我", "打", "他", "他们", "谁", "越 来越。。。"]

sentences = [['我打他。', 'tag'],                #  我，打，他
             ['他打我好疼。', 'tag'],            #  我，打，他
             ['他打谁？', 'tag'],                #      打，他，谁
             ['他们想知道你是谁。', 'tag'],      #          他，谁
             ['钱越来越多。', 'tag']]            #                ，越来越
# ------------------------------------------------------------

new_vocab = Chinese::Vocab.new(1)

words = Chinese::Vocab.unique_words(words)
p words

puts "With target word array:"
with_target_words = new_vocab.add_target_words(sentences, words)

p with_target_words
# [[[["我", "打", "他"], "我打他。"], "tag"],
#  [[["我", "打", "他"], "他打我好疼。"], "tag"],
#  [[["打", "他", "谁"], "他打谁？"], "tag"],
#  [[["他", "谁"], "他们想知道你是谁。"], "tag"],
#  [[["越 来越"], "钱越来越多。"], "tag"]]
puts

puts "Sorted by unique word count:"
sorted_by_unique_word_count = new_vocab.sort_by_unique_word_count(with_target_words)

p sorted_by_unique_word_count
# [[[["越 来越"], "钱越来越多。"], "tag"],
# [[["他", "谁"], "他们想知道你是谁。"], "tag"],
# [[["我", "打", "他"], "他打我好疼。"], "tag"],
# [[["打", "他", "谁"], "他打谁？"], "tag"],
# [[["我", "打", "他"], "我打他。"], "tag"]]
puts


puts "Add tag:"
sorted_with_tag = new_vocab.add_word_count_tag(sorted_by_unique_word_count)

p sorted_with_tag
# [[[["越 来越"], "钱越来越多。"], "tag", "unique_1"],
# [[["他", "谁"], "他们想知道你是谁。"], "tag", "unique_2"],
# [[["我", "打", "他"], "他打我好疼。"], "tag", "unique_3"],
# [[["打", "他", "谁"], "他打谁？"], "tag", "unique_3"],
# [[["我", "打", "他"], "我打他。"], "tag", "unique_3"]]
puts

puts "Minimum necessary sentences:"
minimum_sentences = new_vocab.minimum_necessary_sentences(sorted_with_tag, words)

p minimum_sentences
# [[[["我", "打", "他"], "我打他。"], "tag", "unique_3"],
# [[["谁"], "他打谁？"], "tag", "unique_3"],
# [[["越 来越"], "钱越来越多。"], "tag", "unique_1"]]
puts

puts "Remove unique words arrays:"
without_unique_word_arrays = new_vocab.remove_words_array(minimum_sentences)

p without_unique_word_arrays
# [["我打他。", "tag", "unique_3"],
#  ["他打谁？", "tag", "unique_3"],
#  ["钱越来越多。", "tag", "unique_1"]]
puts

test_result = new_vocab.contains_all_unique_words?(without_unique_word_arrays, words)
puts "Contains all unique words? => #{test_result}."


puts "To file:"
new_vocab.to_file('chinese_test.txt', without_unique_word_arrays, :col_sep => '|')

