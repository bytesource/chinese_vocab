# encoding: utf-8
require 'thread'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'csv'
require 'string_to_pinyin'

module Chinese
  class Vocab
    attr_reader :words


    def option_specs
      {:compress => {:validate => lambda {|value| is_boolean?(value) },
                     :default  => true}}
    end


    # def initialize(word_array, options)
    #   @words = clean_words(word_array)

    # end


    # Input:
    # path_to_csv: Path to CSV file
    # word_col   : Number of the word column we want to extract.
    # options    : Options used by the CSV class
    # Output:
    # Array of strings, where each string is a word from the CSV file.
    def self.words(path_to_csv, word_col, options={})
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

    # Remove all parens and all data in between.
    def clean_words(word_array)
      word_array.map {|word| remove_parens(word) }
    end

    # Input:
    # column: word column number (counting from 1)
    # row   : Array of the processed CSV data that contains our word column.
    def self.within_range?(column, row)
      no_of_cols = row.size
      column >= 1 && column <= no_of_cols
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
