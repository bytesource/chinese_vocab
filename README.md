# Chinese::Vocab

`Chinese::Vocab` is meant to make live easier for any Chinese language student who:

* Prefers to learn vocabulary from Chinese sentences.
* Needs to memorize a lot of words on a __tight time schedule__.
* Uses the spaced repetition flashcard program [Anki](http://ankisrs.net/).

`Chinese::Vocab` addresses all of the above requirements by downloading sentences for each word and selecting the __minimum required number of Chinese sentences__ (and English translations) to represent all words.

You can then export the sentences as well as additional tags provided by `Chinese::Vocab` to Anki.

## Features

* Downloads sentences for each word in a Chinese vocabulary list and selects the __minimum required number of sentences__ to represent all words.
* With the option key `:compact` set to `true` on initialization, all single character words that also appear in at least one multi character word are removed. The reason behind this option is to __remove redundancy in meaning__ and focus on learning distinct words. Example: (["看", "看书"] => [看书])
* Adds additional __tags__ to every sentence that can be used in *Anki*:
 * __Pinyin__: By default the pinyin representation is added to each sentence. Example: "除了这张大钞以外，我没有其他零票了。" => "chú le zhè zhāng dà chāo yĭ wài ，wŏ méi yŏu qí tā líng piào le 。"
 * __Number of target words__: The number of words from the vocabulary that are covered by a sentence. Example: "除了这张大钞以外，我没有其他零票了。" => "3_words"
 * __List of target words__: A list of the words from the vocabulary that are covered by a sentence. Example: "除了这张大钞以外，我没有其他零票了。" => "[我, 他, 除了 以外]"
* Export data to csv for easy import from *Anki*.


## Real World Example (using the Traditional HSK word list)

```` ruby
# Import words from source.
# First argument:  path to file
# Second argument: column number of word column (counting starts at 1)
words = Chinese::Vocab.parse_words('../old_hsk_level_8828_chars_1_word_edited.csv', 4)
# Sample output:
words.take(6)
# => ["啊", "啊", "矮", "爱", "爱人", "安静"]


# Initialize an object.
# First argument:  word list as an array of strings.
# Options:
# :compact (defaults to false)
anki = Chinese::Vocab.new(words, :compact => true)

# List all words
p anki.words.take(6)
# => ["啊", "啊", "矮", "爱", "爱人", "安静"]
p anki.words.size
# => 7251

# Options:
# :source (defaults to :nciku)
# :size   (defaults to :short)
# :with_pinyin (defaults to true)
anki.min_sentences(:thread_count => 10)

p anki.stored_sentences.take(2)
# [{:word=>"吧", :chinese=>"放心吧，他做事向来把牢。",
#   :pinyin=>"fàng xīn ba ，tā zuò shì xiàng lái bă láo 。",
#   :english=>"Take it easy. You can always count on him."},
#  {:word=>"喝", :chinese=>"喝酒挂红的人一般都很能喝。",
#   :pinyin=>"hē jiŭ guà hóng de rén yī bān dōu hĕn néng hē 。",
#   :english=>"Those whose face turn red after drinking are normally heavy drinkers."}]

# words not found
p anki.not_found
# ["来回来去", "来看来讲", "深美"]

# Number of unique characters in the selected sentences
p anki.sentences_unique_chars.size
# => 3290

# Save data to csv.
# First parameter: path to file
# Options:
# Any supported option of Ruby's CSV libary
anki.to_csv('in_the_wild_test.csv')

````

## Documentation
* [parse_words](http://rubydoc.info/github/bytesource/chinese_vocab/master/Chinese/Vocab.parse_words) - How to read in the Chinese words and correctly set the column number, Options:
 * The [supported options](http://ruby-doc.org/stdlib-1.9.3/libdoc/csv/rdoc/CSV.html#method-c-new) of Ruby's CSV library as well as the `:encoding` parameter. __Note__: `:encoding` is always set to `utf-8` and `:skip_blanks` to `true` internally.
* [initialize](http://rubydoc.info/github/bytesource/chinese_vocab/master/Chinese/Vocab:initialize) - How to write composite expressions such as "除了。。以外", Options:
 * `:compress` (`Boolean`): Whether or not to remove all single character words that
also appear in at least one multi character word. Example: (["看", "看书"] => [看书]). The reason behind this option is to remove redundancy in meaning and focus on learning distinct words.
* [words](http://rubydoc.info/github/bytesource/chinese_vocab/master/Chinese/Vocab:words) - Learn how words are edited internally.
* [min_sentences](http://rubydoc.info/github/bytesource/chinese_vocab/master/Chinese/Vocab:min_sentences) - Options:
 * `:source` (`Symbol`): The online dictionary to download the sentences from, either [:nciku](http://www.nciku.com) or [:jukuu](http://www.jukuu.com). Defaults to `:nciku`. __Note__: Despite the download source chosen (by using the default or setting the `:source` options), if a word was not found on the first site, the second site is used as an alternative.
 *  `:with_pinyin` (`Boolean`): Whether or not to return the pinyin representation of a sentence. Defaults to `true`.
 *  `:size` (`Symbol`): The size of the sentence to return from a possible set of several sentences. Supports the values `:short`, `:average`, and `:long`. Defaults to `:short`.
 * `:thread_count` (`Integer`): The number of threads used to download the sentences. Defaults to `8`.
* [sentences_unique_chars](http://rubydoc.info/github/bytesource/chinese_vocab/master/Chinese/Vocab:sentences_unique_chars) - List of unique Chinese *characters* (single character words) are found in the selected sentences.
* [to_csv](http://rubydoc.info/github/bytesource/chinese_vocab/master/Chinese/Vocab:to_csv) - Options:
 * All [supported options](http://ruby-doc.org/stdlib-1.9.3/libdoc/csv/rdoc/CSV.html#method-c-new) of Ruby's CSV library.



