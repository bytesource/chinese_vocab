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


    def min_sentences(options={})
      return @sentences  unless @sentences.empty?

      with_pinyin = validate(:with_pinyin, options, Validations[:with_pinyin], false)

      queue     = Queue.new
      semaphore = Mutex.new
      @words.each {|word| queue << word }
      result = []

      5.times.map {
        Thread.new do

          while(!queue.empty?) do
            word = queue.pop

            scraper = Scraper.new(word, options)
            sentence_pair = scraper.sentence(options)

            # If word not found try again using the alternate download source:
            alternate = alternate_source(Scraper::Sources.keys, scraper.source)
            sentence_pair = scraper.sentence(:source => alternate)   if sentence_pair.empty?


            if sentence_pair.empty?
              @not_found << word
            else
              chinese, english = sentence_pair
              pinyin           = chinese.to_pinyin   if with_pinyin
              # 'pinyin' will be nil if not set, so we need to remove it here.
              local_result = [word, chinese, pinyin, english].compact

              semaphore.synchronize { result << local_result }
            end
          end
        end
      }.each {|thread| thread.join }

      @sentences = result
      @sentences
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
