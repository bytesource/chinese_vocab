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
# [{:chinese=>"小红经常向别人夸示自己有多贤惠。",
#   :pinyin=>"xiăo hóng jīng cháng xiàng bié rén kuā shì zì jĭ yŏu duō xián huì 。",
#   :english=>"Xiaohong always boasts that she is genial and prudent.",
#   :target_words=>["别人", "经常", "自己", "贤惠"]},
#  {:chinese=>"一年一度的圣诞节购买礼物的热潮.",
#   :pinyin=>"yī nián yī dù de shèng dàn jié gòu măi lĭ wù de rè cháo yī",
#   :english=>"the annual Christmas gift-buying jag",
#   :target_words=>["礼物", "购买", "圣诞节", "热潮", "一度"]}]

# Save data to csv.
# First parameter: path to file
# Options:
# Any supported option of Ruby's CSV libary
anki.to_csv('in_the_wild_test.csv')
# Sample output: 2 sentences (csv rows) of 4431 sentences total
# (Note that we started out with 7248 sentences):

# 小红经常向别人夸示自己有多贤惠。,
# xiăo hóng jīng cháng xiàng bié rén kuā shì zì jĭ yŏu duō xián huì 。,
# Xiaohong always boasts that she is genial and prudent.,
# 4_words,"[别人, 经常, 自己, 贤惠]"
#
# 一年一度的圣诞节购买礼物的热潮.,
# yī nián yī dù de shèng dàn jié gòu măi lĭ wù de rè cháo yī,
# the annual Christmas gift-buying jag,
# 5_words,"[一度, 圣诞节, 热潮, 礼物, 购买]"




#### Additional methods

# List all words
p anki.words.take(6)
# => ["啊", "啊", "矮", "爱", "爱人", "安静"]

p anki.words.size
# => 7251

p anki.stored_sentences.take(2)
# [{:chinese=>"小红经常向别人夸示自己有多贤惠。",
#   :pinyin=>"xiăo hóng jīng cháng xiàng bié rén kuā shì zì jĭ yŏu duō xián huì 。",
#   :english=>"Xiaohong always boasts that she is genial and prudent.",
#   :target_words=>["别人", "经常", "自己", "贤惠"]},
#  {:chinese=>"一年一度的圣诞节购买礼物的热潮.",
#   :pinyin=>"yī nián yī dù de shèng dàn jié gòu măi lĭ wù de rè cháo yī",
#   :english=>"the annual Christmas gift-buying jag",
#   :target_words=>["礼物", "购买", "圣诞节", "热潮", "一度"]}]

# Words not found on neither online dictionary.
p anki.not_found
# ["来回来去", "来看来讲", "深美"]

# Number of unique characters in the selected sentences
p anki.sentences_unique_chars.size
# => 3232
