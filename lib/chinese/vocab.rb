# encoding: utf-8
require 'thread'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'csv'
require 'string_to_pinyin'
require 'chinese/scraper'
require 'chinese/modules/options'

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

            sentence_pair = Scraper.new(word, options).sentence(options)

            # If a word was not found, try again using the alternate download source:
            alternate     = alternate_source(Scraper::Sources.keys, options[:source])
            options       = options.merge(:source => alternate)
            sentence_pair = Scraper.new(word, options).sentence(options)  if sentence_pair.empty?


            if sentence_pair.empty?
              @not_found << word
            else
              chinese, english = sentence_pair
              pinyin = chinese.to_pinyin  if with_pinyin
              # 'pinyin' will be nil if 'with_pinyin' is false.
              # We remove those nil-entries with 'compact'.
              local_result = [word, chinese, pinyin, english].compact

              semaphore.synchronize { result << local_result }
            end
          end
        end
      }.each {|thread| thread.join }

      @stored_sentences = result
      @stored_sentences
    end

    def min_sentences(options = {})
      # Always run this method.
      sentences = sentences(options)
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

    # Temporary use hash to faciliate further processing.
    # Input: ["浮鞋", "舌型浮鞋", "shé xíng fú xié", "flapper float shoe"]
    # Output: {word: "浮鞋", sentence: ["舌型浮鞋", "shé xíng fú xié", "flapper float shoe"]}
    def to_temp_hash(arr)
      word      = arr.shift
      sentence = arr
      {word: word, sentence: sentence}
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
