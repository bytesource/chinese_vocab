# encoding: utf-8
module Chinese
  class HSK
    attr_reader :col

    def initialize(sentence_col=1)
      @col = sentence_col - 1
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
      queue     = Queue.new
      semaphore = Mutex.new
      with_target_words = []
      csv_data.each {|row| queue << row}

      10.times.map {
        Thread.new do
          while(row = queue.pop) # pop returns nil if called on an empty array
            sentence  = row[@col]
            puts "Just grabbed sentence: #{sentence}"
            # Make a copy to avoid access by several thread at the same time in #add_words_included
            uniques   = unique_words.dup
            row[@col] = add_words_included(sentence, uniques)
            semaphore.synchronize {
              with_target_words << row
            }
          end
        end
      }.each {|thread| thread.join}

      with_target_words
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



    def minimum_necessary_sentences(sorted_by_unique_word_count, unique_words)
      puts "minimum_necessary_sentences: start"
      rows    = sorted_by_unique_word_count.reverse  # We start with the sentences that contain the most unique words.

      selected_rows   = []
      removed_words   = []
      remaining_words = unique_words

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
        row[@col]   = sentence
        row
      }
    end


    def contains_all_unique_words?(csv_data, unique_words)
      puts "contains_all_unique_words?: start"
      unique_word_size   = unique_words.size

      unique_words_found = unique_words.reduce(0) do |sum,word|

        already_found = csv_data.find {|row|
          sentence = row[@col]
          include_every_char?(word, sentence)
        }
        if already_found
          sum += 1
          sum
        end
      end

      unique_words_found == unique_word_size
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
