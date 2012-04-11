# encoding: utf-8
require 'thread'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'csv'
require 'string_to_pinyin'
require 'chinese/scraper'
require 'chinese/modules/options'
require 'chinese/modules/helper_methods'
require 'chinese/core_ext/hash'
require 'chinese/core_ext/queue'

module Chinese
  class Vocab
    include Options
    include HelperMethods

    attr_reader :words
    #@return [Boolean] the value of the _:compact_ options key.
    attr_reader :compact
    #@return [Array<String>] holds those Chinese words from {#words} that could not be found in any
    # of the supported online dictionaries during a call to either {#sentences} or {#min_sentences}.
    # Defaults to `[]`.
    attr_reader :not_found
    #@return [Boolean] the value of the _:with_pinyin_ option key.
    attr_reader :with_pinyin
    #@return [Array<Hash>] holds the return value of either {#sentences} or {#min_sentences},
    #  whichever was called last. Defaults to `[]`.
    attr_reader :stored_sentences

    # Mandatory constant for the {Options} module. Each key-value pair is of the following type:
    #  option_key => [default_value, validation]
    OPTIONS = {:compact      => [false, lambda {|value| is_boolean?(value) }],
               :with_pinyin  => [true,  lambda {|value| is_boolean?(value) }],
               :thread_count => [8,     lambda {|value| value.kind_of?(Integer) }]}

    # Intializes an object.
    # @overload initialize(word_array, options)
    #  @param [Array<String>] word_array An array of Chinese words that is stored in {#words} after
    #   all non-ascii, non-unicode characters have been stripped and double entries removed.
    #  @param [Hash] options The options to customize the following feature.
    #  @option options [Boolean] :compact Whether or not to remove all single character words that
    #   also appear in at least one multi character word. Example: (["看", "看书"] => [看书])
    #   The reason behind this option is to remove redundancy by focusing on learning
    #   distinct characters.
    #   Defaults to `false`.
    # @overload initialize(word_array)
    # @param [Array<String>] word_array An array of Chinese words that is stored in {#words} after
    #  all non-ascii, non-unicode characters have been stripped and double entries removed.
    # @example (see #sentences_unique_chars)
    def initialize(word_array, options={})
      @compact = validate { :compact }
      @words    = edit_vocab(word_array)
      @words    = remove_redundant_single_char_words(@words)  if @compact
      @chinese  = is_unicode?(@words[0])
      @not_found        = []
      @stored_sentences = []
    end


    # Extracts the vocabulary column from a CSV file as an array of strings. The array is
    #   normally provided as an argument to {#initialize}
    # @overload parse_words(path_to_csv, word_col, options)
    #  @param [String] path_to_csv The relative or full path to the CSV file.
    #  @param [Integer] word_col The column number of the vocabulary column (counting starts at 1).
    #  @param [Hash] options The [supported options](http://ruby-doc.org/stdlib-1.9.3/libdoc/csv/rdoc/CSV.html#method-c-new) of Ruby's CSV library as well as the `:encoding` parameter.
    #    Exceptions: `:encoding` is always set to `utf-8` and `:skip_blanks` to `true`.
    # @overload parse_words(path_to_csv, word_col)
    #  @param [String] path_to_csv The relative or full path to the CSV file.
    #  @param [Integer] word_col The column number of the vocabulary column (counting starts at 1).
    # @return [Array<String>] The vocabluary (Chinese words)
    # @example (see #sentences_unique_chars)
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


    # For every Chinese word in {#words} fetches a Chinese sentence and its English translation
    # from an online dictionary,
    # @note (Normally you only call this method directly if you really need one sentence
    #  per Chinese word (even if these words might appear in more than one of the sentences.).
    # @note (see #min_sentences)
    # @overload sentences(options)
    #  @param [Hash] options The options to customize the following features.
    #  @option options [Symbol] :source The online dictionary to download the sentences from,
    #    either [:nciku](http://www.nciku.com) or [:jukuu](http://www.jukuu.com).
    #    Defaults to *:nciku*.
    #  @option options [Symbol] :size The size of the sentence to return from a possible set of
    #    several sentences. Supports the values *:short*, *:average*, and *:long*.
    #    Defaults to *:short*.
    #  @option options [Boolean] :with_pinyin Whether or not to return the pinyin representation
    #    of a sentence.
    #    Defaults to `true`.
    #  @option options [Integer] :thread_count The number of threads used to download the sentences.
    #    Defaults to `8`.
    # @return [Hash] By default each hash holds the following key-value pairs (The return value is also stored in {#stored_sentences}.):
    #
    #    * :chinese => Chinese sentence
    #    * :english => English translation
    #    * :pinyin  => Pinyin
    #   The return value is also stored in {#stored_sentences}.
    # @example
    #  require 'chinese_vocab'
    #
    #  # Extract the Chinese words from a CSV file.
    #  words = Chinese::Vocab.parse_words('path/to/file/hsk.csv', 4)
    #
    #  # Initialize Chinese::Vocab with word array
    #  # :compact => true means single character words are that also appear in multi-character
    #  # words are removed from the word array (["看", "看书"] => [看书])
    #  vocabulary = Chinese::Vocab.new(words, :compact => true)
    #
    #  # Return a sentence for each word
    #  vocabulary.sentences(:size => small)
    def sentences(options={})
      puts "Fetching sentences..."
      # Always run this method.

      # We assign all options to a variable here (also those that are passed on)
      # as we need them in order to calculate the id.
      @with_pinyin = validate { :with_pinyin }
      thread_count = validate { :thread_count }
      id           = make_hash(@words, options.to_a.sort)
      words        = @words

      from_queue  = Queue.new
      to_queue    = Queue.new
      file_name   = id

      if File.exist?(file_name)
        puts "examining file"
        words, sentences, not_found = File.open(file_name) { |f| f.readlines }
        words = convert(words)
        convert(sentences).each { |s| to_queue << s }
        @not_found = convert(not_found)

        # Remove file
        File.unlink(file_name)
      end

      words.each {|word| from_queue << word }
      result = []

      Thread.abort_on_exception = false

      1.upto(thread_count).map {
        Thread.new do

          while(word = from_queue.pop!) do
            count = 5

            begin
              local_result = select_sentence(word, options)
              puts "word: #{word}"
              # rescue SocketError, Timeout::Error, Errno::ETIMEDOUT,
              # Errno::ECONNREFUSED, Errno::ECONNRESET, EOFError => e
            rescue Exception => e
              pause = 4
              puts " #{e.message}. Retry in #{pause} second(s)."
              sleep(pause)
              count -= 1
              retry  if count > 0

              raise

            ensure
              from_queue << word  if $!
            end

            to_queue << local_result  unless local_result.nil?

          end
        end
      }.each {|thread| thread.join }

      @stored_sentences = to_queue.to_a
      @stored_sentences
    ensure
      if $!
        sleep 10 # Give the threads enough time to put the word back to the queue.

        File.open(file_name, 'w') do |f|
          p "Writing to file..."
          f.write from_queue.to_a
          f.puts
          f.write to_queue.to_a
          f.puts
          f.write @not_found
        end
      end
    end

    # For every Chinese word in {#words} fetches a Chinese sentence and its English translation
    # from an online dictionary, then calculates and the minimum number of sentences
    # necessary to cover every word in {#words} at least once.
    # The calculation is based on the fact that many words occur in more than one sentence.
    #
    # @note In case of a network error during dowloading the sentences the data fetched
    #  so far is automatically copied to a file after several retries. This data is read and
    #  processed on the next run to reduce the time spend with downloading the sentences
    #  (which is by far the most time-consuming part).
    # @overload min_sentences(options)
    #  @param [Hash] options The options to customize the following features.
    #  @option options [Symbol] :source The online dictionary to download the sentences from,
    #    either [:nciku](http://www.nciku.com) or [:jukuu](http://www.jukuu.com).
    #    Defaults to *:nciku*.
    #  @option options [Symbol] :size The size of the sentence to return from a possible set of
    #    several sentences. Supports the values *:short*, *:average*, and *:long*.
    #    Defaults to *:short*.
    #  @option options [Boolean] :with_pinyin Whether or not to return the pinyin representation
    #    of a sentence.
    #    Defaults to `true`.
    #  @option options [Integer] :thread_count The number of threads used to download the sentences.
    #    Defaults to `8`.
    # @return [Array<Hash>, []] By default each hash holds the following key-value pairs (The return value is also stored in {#stored_sentences}.):
    #
    #    * :chinese => Chinese sentence
    #    * :english => English translation
    #    * :pinyin  => Pinyin
    #    * :uwc     => Unique words count tag (String) of the form "x_words",
    #      where *x* denotes the number of unique words from {#words} found in the sentence.
    #    * :uws     => Unique words string tag (String) of the form "[词语1，词语2，...]",
    #      where *词语* denotes the actual word(s) from {#words} found in the sentence.
    #   The return value is also stored in {#stored_sentences}.
    # @example (see #sentences_unique_chars)
    def min_sentences(options = {})
      @with_pinyin = validate { :with_pinyin }
      # Always run this method.
      thread_count = validate { :thread_count }
      sentences    = sentences(options)

      puts "Calculating the minimum necessary sentences..."
      minimum_sentences = select_minimum_necessary_sentences(sentences)
      # :uwc = 'unique words count'
      with_uwc_tag      = add_key(minimum_sentences, :uwc) {|row| uwc_tag(row[:target_words]) }
      # :uws = 'unique words string'
      with_uwc_uws_tags = add_key(with_uwc_tag, :uws) do |row|
        words = row[:target_words].sort.join(', ')
        "[" + words + "]"
      end
      # Remove those keys we don't need anymore
      result            = remove_keys(with_uwc_uws_tags, :target_words, :word)
      @stored_sentences = result
      @stored_sentences
    end


    # Finds the unique Chinese characters from either the data in {#stored_sentences} or an
    # array of Chinese sentences passed as an argument.
    # @overload sentences_unique_chars(sentences)
    #  @param [Array<String>, Array<Hash>] sentences An array of chinese sentences or an array of hashes with the key `:chinese`.
    # @note If no argument is passed, the data from {#stored_sentences} is used as input
    # @return [Array<String>] The unique Chinese characters
    # @example
    #  require 'chinese_vocab'
    #
    #  # Extract the Chinese words from a CSV file.
    #  words = Chinese::Vocab.parse_words('path/to/file/hsk.csv', 4)
    #
    #  # Initialize Chinese::Vocab with word array
    #  # :compact => true means single character words are that also appear in multi-character
    #  # words are removed from the word array (["看", "看书"] => [看书])
    #  vocabulary = Chinese::Vocab.new(words, :compact => true)
    #
    #  # Return minimum necessary sentences.
    #  vocabulary.min_sentences(:size => small)
    #
    #  # See how what are the unique characters in all these sentences.
    #  vocabulary.sentences_unique_chars(my_sentences)
    #  # => ["我", "们", "跟", "他", "是", "好", "朋", "友", ...]
    #
    #  # Save to file
    #  vocabulary.to_csv('path/to_file/vocab_sentences.csv')
    def sentences_unique_chars(sentences = stored_sentences)
      # If the argument is an array of hashes, then it must be the data from @stored_sentences
      sentences = sentences.map { |hash| hash[:chinese] }  if sentences[0].kind_of?(Hash)

      sentences.reduce([]) do |acc, row|
        acc = acc | row.scan(/\p{Word}/) # only return characters, skip punctuation marks
        acc
      end
    end


    # Saves the data stored in {#stored_sentences} to disk.
    # @overload to_csv(path_to_file, options)
    #  @param [String] path_to_file file name and path of where to save the file.
    #  @param [Hash] options The [supported options](http://ruby-doc.org/stdlib-1.9.3/libdoc/csv/rdoc/CSV.html#method-c-new) of Ruby's CSV library.
    # @overload to_csv(path_to_file)
    #  @param [String] path_to_file file name and path of where to save the file.
    # @return [void]
    # @example (see #sentences_unique_chars)
    def to_csv(path_to_file, options = {})

      CSV.open(path_to_file, "w", options) do |csv|
        @stored_sentences.each do |row|
          csv << row.values
        end
      end
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
      puts "Editing vocabulary..."

      word_array.map {|word|
        edited = remove_parens(word)
        edited = remove_slash(edited)
        edited = remove_er_character_from_end(edited)
        distinct_words(edited).join(' ')
      }.uniq
    end


    def remove_er_character_from_end(word)
      if word.size > 2
      word.gsub(/儿$/, '')
      else # Don't remove "儿" form words like 女儿
        word
      end
    end


    def remove_slash(word)
      if word.match(/\//)
        word.split(/\//).sort_by { |w| w.size }.last
      else
        word
      end
    end


    def make_hash(*data)
      require 'digest'
      data = data.reduce("") { |acc, item| acc << item.to_s }
      Digest::SHA2.hexdigest(data)[0..6]
    end


    # Input: ["看", "书", "看书"]
    # Output: ["看书"]
    def remove_redundant_single_char_words(words)
      puts "Removing redundant single character words from the vocabulary..."

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


    # Uses options passed from #sentences
    def select_sentence(word, options)
      sentence_pair = Scraper.sentence(word, options)

      sources = Scraper::Sources.keys
      sentence_pair = try_alternate_download_sources(sources, word, options)  if sentence_pair.empty?

      if sentence_pair.empty?
        @not_found << word
        return nil
      else
        chinese, english = sentence_pair

        result = Hash.new
        result.merge!(word:    word)
        result.merge!(chinese: chinese)
        result.merge!(pinyin:  chinese.to_pinyin)  if @with_pinyin
        result.merge!(english: english)
      end
    end


    def try_alternate_download_sources(alternate_sources, word, options)
      sources = alternate_sources.dup
      sources.delete(options[:source])

      result = sources.find do |s|
        options  = options.merge(:source => s)
        sentence = Scraper.sentence(word, options)
        sentence.empty? ? nil : sentence
      end

      if result
        optins = options.merge(:source => result)
        Scraper.sentence(word, options)
      else
        []
      end
    end


    def convert(text)
      eval(text.chomp)
    end


    def add_target_words(hash_array)
      puts "Internal: Adding target words..."
      from_queue  = Queue.new
      to_queue    = Queue.new
      # semaphore = Mutex.new
      result      = []
      words       = @words
      puts "add_target_words, words.size = #{words.size}"
      hash_array.each {|hash| from_queue << hash}

      10.times.map {
        Thread.new(words) do

          while(row = from_queue.pop!)
            sentence     = row[:chinese]
            target_words = target_words_per_sentence(sentence, words)

            to_queue << row.merge(:target_words => target_words)

          end
        end
      }.map {|thread| thread.join}

      to_queue.to_a

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
        # Delete all words from 'words' that have already been encoutered
        # (and are included in 'matched_words').
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


    def remove_keys(hash_array, *keys)
      hash_array.map { |row| row.delete_keys(*keys) }
    end


    def add_key(hash_array, key, &block)
      hash_array.map do |row|
        if block
          row.merge({key => block.call(row)})
        else
          row
        end
      end
    end


    def uwc_tag(string)
      size = string.length
      case size
      when 1
        "1_word"
      else
        "#{size}_words"
      end
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

      if matched_words.size == @words.size
        true
      else
        puts "-----------------------------"
        puts "#contains_all_target_words?"
        puts "Words not found:"
        p @words - matched_words
        puts "-----------------------------"
        false
      end

      #matched_words.size == @words.size
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

  end
end
