# Import words from source.
# First argument:  path to file
# Second argument: column number of word column (counting starts at 1)
words = Chinese::Vocab.parse_words('../old_hsk_level_8828_chars_1_word_edited.csv', 4)
# Sample output:
p words.take(6)
# => ["啊", "啊", "矮", "爱", "爱人", "安静"]


# Initialize an object.
# First argument:  word list as an array of strings.
# Options:
# :compact (defaults to false)
anki = Chinese::Vocab.new(words, :compact => true)


# Options:
# :source (defaults to :nciku)
# :size   (defaults to :short)
# :with_pinyin (defaults to true)
anki.min_sentences(:thread_count => 10)
# Sample output:
# [{:word=>"吧", :chinese=>"放心吧，他做事向来把牢。",
#   :pinyin=>"fàng xīn ba ，tā zuò shì xiàng lái bă láo 。",
#   :english=>"Take it easy. You can always count on him."},
#  {:word=>"喝", :chinese=>"喝酒挂红的人一般都很能喝。",
#   :pinyin=>"hē jiŭ guà hóng de rén yī bān dōu hĕn néng hē 。",
#   :english=>"Those whose face turn red after drinking are normally heavy drinkers."}]

# Save data to csv.
# First parameter: path to file
# Options:
# Any supported option of Ruby's CSV libary
anki.to_csv('in_the_wild_test.csv')
# Sample output (2 sentences/lines out of 4511):
# 只要我们有信心，就会战胜困难。,zhī yào wŏ men yŏu xìn xīn ，jiù huì zhàn shèng kùn nán 。,
# "As long as we have confidence, we can overcome difficulties.",
# 5_words,"[信心, 只要, 困难, 我们, 战胜]"
# 至于他什么时候回来，我不知道。,zhì yú tā shén mo shí hòu huí lái ，wŏ bù zhī dào 。,
# "As to what time he's due back, I'm just not sure.",
# 5_words,"[什么, 回来, 时候, 知道, 至于]"


#### Additional methods

# List all words
p anki.words.take(6)
# => ["啊", "啊", "矮", "爱", "爱人", "安静"]

p anki.words.size
# => 7251

p anki.stored_sentences.take(2)
# [{:word=>"吧", :chinese=>"放心吧，他做事向来把牢。",
#   :pinyin=>"fàng xīn ba ，tā zuò shì xiàng lái bă láo 。",
#   :english=>"Take it easy. You can always count on him."},
#  {:word=>"喝", :chinese=>"喝酒挂红的人一般都很能喝。",
#   :pinyin=>"hē jiŭ guà hóng de rén yī bān dōu hĕn néng hē 。",
#   :english=>"Those whose face turn red after drinking are normally heavy drinkers."}]

# Words not found on neither online dictionary.
p anki.not_found
# ["来回来去", "来看来讲", "深美"]

# Number of unique characters in the selected sentences
p anki.sentences_unique_chars.size
# => 3290
