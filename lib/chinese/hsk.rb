# encoding: utf-8
require 'thread'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'string_to_pinyin'

module Chinese
  class HSK
    attr_reader :col, :not_found

    def initialize(sentence_col=1)
      @col = sentence_col - 1
      @not_found = []
    end


    def self.extract_column(data,word_column)
      column = word_column - 1
      data.map {|row| row[column]}
    end


    def self.unique_words(column_data)
      puts "unique_words: start"
      # Remove duplicates
      uniques = column_data.uniq
      # Remove non-characters ("越 。。。来越。。。" => "越 来越"
      uniques = self.new.clean_words(uniques) # dirty hack to call instance method within a class method
      # Remove all single character words that are part of a multi-character word.
      remove_redundant_single_char_words(uniques)
    end

    def self.remove_redundant_single_char_words(unique_words)
      puts "remove_redundant_single_char_words: start"
      single_char_words, multi_char_words = unique_words.partition {|word| word.length == 1 }
      return single_char_words  if multi_char_words.empty?

      non_redundant_single_char_words = single_char_words.reduce([]) {|acc,single_c|

        already_found = multi_char_words.find {|multi_c|
          multi_c.include?(single_c)
        }
        # Add single char word to array if it is not part of any of the multi char words.
        acc << single_c  unless already_found
        acc
      }

      non_redundant_single_char_words + multi_char_words
    end

    def add_sentences(unique_words, source = :nciku)

      queue     = Queue.new
      semaphore = Mutex.new
      unique_words.each {|word| queue << word }
      result = []

      5.times.map {
        Thread.new do

          while(!queue.empty?) do
            word = queue.pop
            url  = 'http://www.nciku.com/search/all/examples/'
            chinese, english = "", ""

            case source.to_sym
            when :nciku
              chinese, english = scrap_nciku(word)
            when :jukuu
              chinese, english = scrap_jukuu(word)
            else
              raise Exception, "'#{source}' is not a valid source. Please choose either :nciku or :jukuu."
            end

            if chinese.empty? || english.empty?
              @not_found << word
            else
              pinyin       = chinese.to_pinyin
              local_result = [word, chinese, pinyin, english]

              semaphore.synchronize { result << local_result }
            end
          end
        end
      }.each {|thread| thread.join }

      result
    end

    # Returns the first [sentence, translation] pair found.
    def scrap_nciku(word)
      word_escaped = CGI.escape(word)
      parent_css   = 'div.examples_box > dl'
      chin_css     = 'dt > span'
      engl_css     = 'dd > span.tc_sub'
      url          = 'http://www.nciku.com/search/all/examples/' + word_escaped

      node = Nokogiri::HTML(open(url)).css(parent_css) # There is only one node at 'parent_css'
      chinese_html = node.at_css(chin_css)      # Return the first match (HTML as String).
      chinese_text = extract_text(chinese_html) # Returns nil if no text is found.
      english_html = node.at_css(engl_css)      # Return the first match (HTML as String).
      english_text = extract_text(english_html) # Returns nil if no text is found.
      [chinese_text, english_text]
    end



    def extract_text(node)
      return "" if node.nil?
      node.text.strip
    end


    def scrap_jukuu(word)
      word_escaped = CGI.escape(word)
      parent_css     = "table#Table1 table[width = '680']"
      chin_css       = '.c > td[2]'
      engl_css       = '.e > td[2]'
      url            = 'http://www.jukuu.com/search.php?q=' + word_escaped

      sentence_pairs = Nokogiri::HTML(open(url)).css(parent_css).map do |node|
        chinese_html = node.at_css(chin_css)      # Return the first (and only) match (HTML as String).
        chinese_text = extract_text(chinese_html) # Returns nil if no text is found.
        english_html = node.at_css(engl_css)      # Return the first (and only) match (HTML as String).
        english_text = extract_text(english_html) # Returns nil if no text is found.
        [chinese_text, english_text]
      end
      second_shortest(remove_pairs_with_empty_items(sentence_pairs))
    end

    # undefined method `empty?' for nil:NilClass
    #  # ./lib/chinese/hsk.rb:76:in `block (2 levels) in add_sentences'



    def remove_pairs_with_empty_items(sentence_pairs)
      sentence_pairs.reject {|(cn,en)| cn.nil? || en.nil? }
    end

    def second_shortest(sentence_pairs)
      sentence_pairs.sort_by {|(cn,_)| cn.length }.take(2).last
    end

    def longest(sentence_pairs)
      sentence_pairs.sort_by {|(cn,_)| cn.length }.last
    end

    def middle_large(sentence_pairs)
      sorted = sentence_pairs.sort_by {|(cn,_)| cn.length }
      length = sorted.length
      sorted.find {|(cn,_)| cn.size >= length/2 }
    end


    def add_target_words(csv_data, unique_words)
      puts "add_target_words"
      csv_data.map {|row|
        row = row.dup      # dup important!
        sentence = row[@col]
        row[@col] = add_words_included(sentence, unique_words)
        row.dup            # dup important!
      }
    end

    def add_target_words_with_threads(csv_data, unique_words)
      puts "add_target_words_with_threads"
      require 'thread'
      from_queue = Queue.new
      semaphore  = Mutex.new
      result     = []
      csv_data.each {|row| from_queue << row}
      counter = 1

      10.times.map {
        Thread.new do

          while(!from_queue.empty?)
            row = from_queue.pop
            sentence  = row[@col]
            # semaphore.synchronize {
            #   puts "#{counter}: Just grabbed sentence: #{sentence}"
            #   counter += 1
            # }
            # Make a copy to avoid access by several thread at the same time in #add_words_included
            local_uniques = []
            semaphore.synchronize { local_uniques   = unique_words.dup }
            row[@col] = add_words_included(sentence, local_uniques)

            semaphore.synchronize { result << row }
          end
        end
      }.map {|thread| thread.join}

      result
    end



    def sort_by_unique_word_count(with_target_words)
      puts "sort_by_unique_word_count"
      # First sort by size of unique word array (small to large)
      # If the unique word count is equal, sort by the length of the sentence (large to small)
      with_target_words.sort_by {|row|
        entry = row[@col]
        [entry[0].size, -entry[1].size] }

        # The above is the same as:
        # with_target_words.sort {|a,b|
        #   (a[@col][0].size <=> b[@col][0].size).nonzero? ||
        #     -(a[@col][1].size <=> b[@col][1].size) }

    end

    def add_word_count_tag(with_target_words, prefix="unique_")
      puts "add_word_count_tag"
      with_target_words.map {|row|
        word_count = row[@col][0].size
        tag = prefix + word_count.to_s
        row << tag
        row
      }
    end

    def add_word_list_and_count_tags(with_target_words, prefix="unique_")
      puts "add_word_list_and_count_tags"
      with_target_words.map {|row|
        word_list  = row[@col][0].dup
        word_count = word_list.size
        # ["他们", "越 来越"] => "[他们] [越 来越]"
        word_list_tag  = word_list.map {|x| "[#{x}]"}.join(' ')
        word_count_tag = prefix + word_count.to_s
        row << word_count_tag << word_list_tag
        row
      }
    end


    def minimum_necessary_sentences(sorted_by_unique_word_count, unique_words)
      puts "minimum_necessary_sentences: start"
      rows = sorted_by_unique_word_count.reverse  # We start with the sentences that contain the most unique words.

      selected_rows   = []
      removed_words   = []
      remaining_words = unique_words.dup

      rows.each do |row|
        words = row[@col][0]
        # Delete all words from 'words' that have already been encoutered (and are included in 'removed_words').
        delete_words_from(words, removed_words)

        if words.size > 0  # Words that where not deleted above have to be part of 'remaining_words'.
          selected_rows << row  # Select this row.
          # Delete all words form 'remaining_words' that have just been encountered.
          delete_words_from(remaining_words, words)
          # Add those words removed from 'remaining_words' to 'removed_words'
          removed_words = removed_words + words
        end
      end
      selected_rows
    end


    # [[[["我", "打", "他"], "我打他。"], "tag"],...] => [["我打他。", "tag"],...]
    def remove_words_array(with_unique_words)
      puts "remove_words_array: start"
      with_unique_words.map {|row|
        target_row = row[@col].dup
        sentence   = target_row[1]
        row[@col]  = sentence
        row
      }
    end


    def contains_all_unique_words?(csv_data, unique_words)
      puts "contains_all_unique_words?: start"

      unique_words_found = unique_words.reduce([]) {|acc,word|

        already_found = csv_data.find {|row|
          sentence = row[@col]
          include_every_char?(word, sentence)
        }
        if already_found
          acc << word
        end
        acc
      }

      p unique_words - unique_words_found if unique_words_found.size != unique_words.size
      puts "Unique words count = #{unique_words.size}."
      puts "Found words size = #{unique_words_found.size}."
      unique_words_found.size == unique_words.size
    end


    def to_file(file_name, data_array, options={})
      puts "to_file: start"
      CSV.open(file_name, "w", options) do |csv|
        data_array.each do |row|
          csv << row
        end
      end
    end



    # Helper functions
    # -----------------

    def include_every_char?(word, sentence)
      characters = split_word(word)
      characters.all? {|char| sentence.include?(char) }
    end

    def split_word(word)
      word = clean_word(word)
      word.split(/\s+/)      # return array of characters that belong together
    end

    def clean_word(word)
      # Replace '。' with whitespace.
      # Remove leading and trailing whitespace that might infer with the following method.
      word.gsub(/。+/, ' ').strip
    end

    def clean_words(words)
      words.map {|word| clean_word(word) }
    end

    def add_words_included(sentence, words)
      words_included = words.select {|w| include_every_char?(w, sentence) }
      [words_included, sentence]
    end

    def delete_words_from(array, words)
      words.each {|word|
        array.delete(word) # delete word from 'words' if present in 'array'
      }
    end
  end
end
