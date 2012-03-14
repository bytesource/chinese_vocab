
vocabulary_source = CSV.read('/path/to/words.csv',  :encoding => 'utf-8')

# If there is more than one column per row, you need to extract the words column first,
# providing the number of column you are interested in (counting starts at 1).
word_list = Learn::Chinese.extract_words(1)

words = Learn::Chinese.unique_words(word_list, :compress => true)

# @words_not_found   = []
# @sentences         = []
# @unique_characters = []
Learn::Chinese(words) do |words|
  words.add_sentences_from('nciku')  # fill up @not_found and @sentences
  words.miniumum_sentences  # calls 'add target_words_with_threads' until 'remove_words_array'
end
