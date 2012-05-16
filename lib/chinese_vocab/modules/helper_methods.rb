# encoding: utf-8

module Chinese
  module HelperMethods

    def self.included(klass)
      klass.extend(self)
    end

    def is_unicode?(word)
      # Remove all non-ascii and non-unicode word characters
      word = distinct_words(word).join
      # English text at this point only contains characters that are matched by \w
      # Chinese text at this point contains mostly/only unicode word characters that are not matched by \w.
      # In case of Chinese text the size of 'char_arr' therefore has to be smaller than the size of 'word'
      char_arr = word.scan(/\w/)
      char_arr.size < word.size
    end

    # Input: "除了。。。 以外。。。"
    # Output: ["除了", "以外"]
    def distinct_words(word)
      # http://stackoverflow.com/a/3976004
      # Alternative: /[[:word:]]+/
      word.scan(/\p{Word}+/)      # Returns an array of characters that belong together.
    end

    # Return true if every distinct word as defined by {#distinct_words}
    # can be found in the given sentence.
    def include_every_char?(word, sentence)
      characters = distinct_words(word)
      characters.all? {|char| sentence.include?(char) }
    end


  end
end

