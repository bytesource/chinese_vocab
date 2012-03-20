# encoding: utf-8

module Chinese
  class Compacter


    def find_target_words_in_sentence(sentence, words)
      words.select {|w| include_every_char?(w, sentence) }
    end

    def include_every_char?(word, sentence)
      word = split_word(word)
      # A word might be something like this: "除了 以外“
      # The function tests if both "除了" and "以外“ can be found in the sentence.
      word.all? {|char| sentence.include?(char) }
    end

    # split_word("除了。。。以外")
    # => ["除了", "以外"]
    def split_word(word)
      # http://stackoverflow.com/a/3976004
      word.scan(/\p{Word}+/) # Return array of characters that belong together.
      # Alternative: /[[:word:]]+/
      # word.scan(/[[:word:]]+/) # Return array of characters that belong together.
    end

  end
end
