# encoding: utf-8
require 'thread'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'csv'
require 'string_to_pinyin'
require 'chinese/scraper'
require 'chinese/modules/options'
require 'chinese/core_ext/hash'

module Chinese
  class Vocab
    include Options

    attr_reader :words, :compress, :chinese, :not_found

    Validations = {:compress    => lambda {|value| is_boolean?(value) },
                   :with_pinyin => lambda {|value| is_boolean?(value) }}


    def initialize(word_array, options={})
      # TODO: extend 'edit_vocab to also handle English text properly (e.g. remove 'somebody', 'someone', 'so', 'to do sth' etc)
      @compress = validate(:compress, options, Validations[:compress], false)
      @words    = edit_vocab(word_array)
      @words    = remove_redundant_single_char_words(@words)  if @compress
      @chinese  = is_unicode?(@words[0])
      @not_found     = []
      @sentences     = []
      @min_sentences = []
    end


    # Input:
    # path_to_csv: Path to CSV file
    # word_col   : Number of the word column we want to extract.
    # options    : Options used by the CSV class
    # Output:
    # Array of strings, where each string is a word from the CSV file.
    def self.parse_words(path_to_csv, word_col, options={})
      # Enforced options:
      # encoding: utf-8 (necessary for parsing Chinese characters)
      # skip_blanks: true
      options.merge!({:encoding => 'utf-8', :skip_blanks => true})
      csv = CSV.read(path_to_csv, options)

      raise ArgumentError, "Column number (#{word_col}) out of range."  unless within_range?(word_col, csv[0])
      # 'word_col counting starts at 1, but CSV.read returns an array,
      # where counting starts at 0.
      col = word_col-1
      csv.reduce([]) {|words, row|
        word = row[col]
        # If word_col contains no data, CSV::read returns nil.
        # We also want to skip empty strings or strings that only contain whitespace.
        words << word  unless word.nil? || word.strip.empty?
        words
      }
    end


    def sentences(options={})
      # Always run this method.

      with_pinyin = validate(:with_pinyin, options, Validations[:with_pinyin], false)

      queue     = Queue.new
      semaphore = Mutex.new
      @words.each {|word| queue << word }
      result = []

      5.times.map {
        Thread.new do

          while(!queue.empty?) do
            word = queue.pop

            local_result = select_sentence(word, options)

            semaphore.synchronize { result << local_result }
          end
        end
      }.each {|thread| thread.join }

      @stored_sentences = result
      @stored_sentences
    end


    # options - The Hash options used to refine the selection (default: {}):
    #           :color  - The String color to restrict by (optional).
    #           :weight - The Float weight to restrict by. The weight should
    #                     be specified in grams (optional).

    # Public: Select the minimum number of sentences necessary to cover all word characters.
    #
    # options - The Hash options used to refine the selection (default: {}):
    #           :with_pinyin - The Boolean to decide if the pinyin representation of a Chinese sentence
    #                          should be returned, too (default: true)
    #
    # Examples
    #
    #   min_sentenes(:pinyin => false)
    #   #
    #
    # Returns an Array of Hash objects
    def min_sentences(options = {})
      with_pinyin = validate(:with_pinyin, options, Validations[:with_pinyin], true)
      # Always run this method.
      sentences         = sentences(options)
      minimum_sentences = select_minimum_sentences(sorted_by_target_word_count)
      minimum_sentences.map { |row| row.delete_keys(:target_words, :words) }
    end


    # Helper functions
    # -----------------

    def remove_parens(word)
      # 1) Remove all ASCII parens and all data in between.
      # 2) Remove all Chinese parens and all data in between.
      word.gsub(/\(.*?\)/, '').gsub(/（.*?）/, '')
    end


    def is_boolean?(value)
      # Only true for either 'false' or 'true'
      !!value == value
    end


    # Remove all non-word characters
    def edit_vocab(word_array)
      word_array.map {|word|
        edited = remove_parens(word)
        distinct_words(edited).join(' ')
      }.uniq
    end


    # Input: ["看", "书", "看书"]
    # Output: ["看书"]
    def remove_redundant_single_char_words(words)
      single_char_words, multi_char_words = words.partition {|word| word.length == 1 }
      return single_char_words  if multi_char_words.empty?

      non_redundant_single_char_words = single_char_words.reduce([]) do |acc, single_c|

        already_found = multi_char_words.find do |multi_c|
          multi_c.include?(single_c)
        end
        # Add single char word to array if it is not part of any of the multi char words.
        acc << single_c  unless already_found
        acc
      end

      non_redundant_single_char_words + multi_char_words
    end


    def select_sentence(word, options)
      sentence_pair = Scraper.new(word, options).sentence(options)

      # If a word was not found, try again using the alternate download source:
      alternate     = alternate_source(Scraper::Sources.keys, options[:source])
      options       = options.merge(:source => alternate)
      sentence_pair = Scraper.new(word, options).sentence(options)  if sentence_pair.empty?

      if sentence_pair.empty?
        @not_found << word
      else
        chinese, english = sentence_pair

        result = Hash.new
        result.merge!(word:    word)
        result.merge!(chinese: chinese)
        result.merge!(pinyin:  chinese.to_pinyin)  if options[:with_pinyin]
        result.merge!(english: english)
      end
    end


    def add_target_words(hash_array)
      queue      = Queue.new
      semaphore  = Mutex.new
      result     = []
      hash_array.each {|hash| queue << hash}

      10.times.map {
        Thread.new do

          while(!queue.empty?)
            row       = queue.pop
            sentence  = row[:chinese]

            target_words = target_words_per_sentence(sentence, @words)

            semaphore.synchronize { result << row.merge(:target_words => target_words) }
          end
        end
      }.map {|thread| thread.join}

      result
    end


    def target_words_per_sentence(sentence, words)
       words.select {|w| include_every_char?(w, sentence) }
    end


    def sort_by_target_word_count(with_target_words)
      # First sort by size of unique word array (from large to short)
      # If the unique word count is equal, sort by the length of the sentence (from small to large)
      with_target_words.sort_by {|row|
        [-row[:target_words].size, row[:chinese].size] }

        #  The above is the same as:
        #   with_target_words.sort {|a,b|
        #     first = -(a[:target_words].size <=> b[:target_words].size)
        #     first.nonzero? || (a[:chinese].size <=> b[:chinese].size) }
    end


    def select_minimum_necessary_sentences(sentences)
      with_target_words = add_target_words(sentences)
      rows              = sort_by_target_word_count(with_target_words)

      selected_rows   = []
      unmatched_words = @words.dup
      matched_words   = []

      rows.each do |row|
        words = row[:target_words].dup
        # Delete all words from 'words' that have already been encoutered (and are included in 'matched_words').
        words = words - matched_words

        if words.size > 0  # Words that where not deleted above have to be part of 'unmatched_words'.
          selected_rows << row  # Select this row.

          # When a row is selected, its 'words' are no longer unmatched but matched.
          unmatched_words = unmatched_words - words
          matched_words   = matched_words + words
        end
      end
      selected_rows
    end


    def contains_all_target_words?(selected_rows, sentence_key)

      matched_words = @words.reduce([]) do |acc, word|

        result = selected_rows.find do |row|
          sentence = row[sentence_key]
          include_every_char?(word, sentence)
        end

        if result
          acc << word
        end

        acc
      end

      matched_words.size == @words.size
    end


    def is_unicode?(word)
      # Remove all non-ascii and non-unicode word characters
      word = distinct_words(word).join
      # English text at this point only contains characters that are mathed by \w
      # Chinese text at this point contains mostly/only unicode word characters that are not matched by \w.
      # In case of Chinese text the size of 'char_arr' therefore has to be smaller than the size of 'word'
      char_arr = word.scan(/\w/)
      char_arr.size < word.size
    end


    # Input:
    # column: word column number (counting from 1)
    # row   : Array of the processed CSV data that contains our word column.
    def self.within_range?(column, row)
      no_of_cols = row.size
      column >= 1 && column <= no_of_cols
    end


    def alternate_source(sources, selection)
      sources = sources.dup
      sources.delete(selection)
      sources.pop
    end


    # Return true if every distince word (as defined by #distinct_words)
    # can be found in the given sentence.
    def include_every_char?(word, sentence)
      characters = distinct_words(word)
      characters.all? {|char| sentence.include?(char) }
    end


    # Input: "除了。。。 以外。。。"
    # Outout: ["除了", "以外"]
    def distinct_words(word)
      # http://stackoverflow.com/a/3976004
      # Alternative: /[[:word:]]+/
      word.scan(/\p{Word}+/)      # Returns an array of characters that belong together.
    end

  end
end
