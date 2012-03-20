vocab_source = CSV.read('/path/to/words.csv',  :encoding => 'utf-8')

Chinese::Vocab.words('/path/to/words.csv', 1)
# Uses :encoding => 'utf-8' internally
# Returns a string of characters

# @words_not_found   = []
# @sentences         = []
# @unique_characters = []

sentences = Chinese::Vocab.new do |words|
  words.miniumum_sentences(:source => 'nciku')
  words.to_cvs('path/to/file.csv', :col_sep => '|')
end
