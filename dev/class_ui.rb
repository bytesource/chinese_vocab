
vocabulary_source = CSV.read('/path/to/words.csv',  :encoding => 'utf-8')

# If there is more than one column per row, you need to extract the words column first,
# providing the number of column you are interested in (counting starts at 1).
word_list = Learn::Chinese.extract_words(1)

words = Learn::Chinese.unique_words(word_list, :language => :cn, :compress => true) # :compress is ignored if :cn is choosen
# defaults:
# :language => :cn
# :compress => false

# @words_not_found   = []
# @sentences         = []
# @unique_characters = []
Learn::Chinese(words) do |words|
  words.add_sentences_from('nciku')  # fill up @not_found and @sentences
  words.miniumum_sentences  # calls 'add target_words_with_threads' until 'remove_words_array'
  # 'minimum sentences only available for :language => :cn
  words.to_cvs('path/to/file.csv', :col_sep => '|')
end
