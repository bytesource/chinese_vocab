# encoding: utf-8

# ======================================================
puts "New start with Hash"
# ===========================

require 'cgi'
require 'open-uri'
require 'nokogiri'

class HSK
  attr_reader :data


  def initialize(raw_data)
    @data = raw_data
  end


  # Add content to a column (normally a tag)
  # based on the content of another column.
  # To be called before #replace_words to handle
  # remaining empty tag columns.
  def add_tags(from, to, conditions)
    from = from-1
    to   = to-1
    @data = data.map {|row|
      string = row[from]
      tags = word_array(row[to])
      conditions.each do |cond|
        tag = cond.call(string)
        tags << tag  unless tag.nil?
      end

      row[to] = tags
      row
    }
  end




  def replace_words(col, replacements)
    col = col-1
    @data = data.map {|row|
      old_words = word_array(row[col])
      new_words = old_words.map {|word|
        if replacement = replacements[word]
          replacement
        else
          word
        end
      }
      row[col] = new_words
      row
    }
  end



  def merge_duplicate_words(columns_to_be_merged)
    frequency   = duplicate_words
    cols        = normalize_cols(columns_to_be_merged)
    temp_data   = {}

    @data = data.each_with_object([]) {|row,merged|
      word = row[3]
      if frequency.include?(word)
        # Check if word has already been encountered
        if temp_data[word] # already encountered
          if frequency[word] == 1     # we won't encounter another duplicate of this word
            temp_data[word].each do |col,data|
              # Merge data
              # 'data' has already been converted into an array
              row[col] = data | word_array(row[col])  # | = remove duplicates
              # row[col].uniq
            end
            merged << row
          else            # word already encountered but frequency not null yet
            before = frequency[word]
            frequency[word] -= 1
            after = frequency[word]
            # Add data to temp
            cols.each do |col|
              # temp_data[word][col] has already been converted into an array
              temp_data[word][col] | word_array(row[col])
            end
          end
        else # not encountered yet
          temp_data[word] = Hash[cols.map {|col| # {word => {col => [...]}}
            [ col, word_array(row[col]) ] # {col => [ ...]}
          }]
          frequency[word] -= 1
        end
      else  # no duplicate
        merged << row
      end
    }
  end

  def merge_cols(from, to)
    from_cols = normalize_cols(from)
    to_col    = to - 1
    @data = data.map {|row|
      from_cols.each do |col|
        row[to_col] = word_array(row[to_col]) | word_array(row[col])
      end
      row
    }
  end


  def add_sentences_from(uri, word_column, options = {})
    raise Exception, "CSS for sentence not specified."     if options[:sentence_css].nil?
    raise Exception, "CSS for translation not specified."  if options[:translation_css].nil?
    #raise Exception, "CSS for pinyin not specified."       if options[:pinyin].nil?

    require 'thread'
    mutex = Mutex.new

    data.map.with_index do |row, i|

      thread = Thread.new(row) do

        word = CGI.escape(row[word_column-1])
        url  = uri.gsub(/{}/, word)
        doc  = Nokogiri::HTML(open(url))

        parent_css      = options[:parent_css]
        sentence_css    = options[:sentence_css]
        translation_css = options[:translation_css]

        result = scrap_all(doc, parent_css, sentence_css, translation_css)
        # Todo: remove nil entries
        final_match = select_shortest(0, result)

        row << final_match
        @data[i] = row
      end

      thread
    end.each do |thread|
      thread.join
    end
    data
  end


  def to_file(file_name, data_array, options={})
    CSV.open(file_name, "w", options) do |csv|
      data_array.each do |row|
        entries_to_string = row.map {|entry| word_string(entry) }
        csv << entries_to_string
      end
    end
  end



  # Helper methods
  # -----------------

  def normalize_cols(cols)
    cols.map {|col| col-1}.uniq.sort
  end

  def duplicate_words
    word_frequency_hash = data.each_with_object(Hash.new(0)) {|row, words|
      word = row[3]
      words[word] += 1
    }
    duplicates_hash = word_frequency_hash.select {|word,freq| freq > 1}
    duplicates_hash
  end


  def unique_words(col)
    col = col-1
    data.each_with_object(Hash.new(0)) {|row, hash|
      word_array(row[col]).each do |word|
        hash[word] += 1
      end
    }
  end

  def rows_with_empty_col(col)
    col = col-1
    @data.select {|row| word_array(row[col]).empty? }
  end


  def scrap_all(doc, parent_css, sentence_css, translation_css)
  #   result = doc.css(parent_css).map {|node|
  #     # sentence = node.css(sentence_css).first.text.strip
  #     chin_pinyin = node.to_s.scan(/newTTS\((?<target>[^)]+)/)
  #     if chin_pinyin.size
  #     translation = node.css(translation_css).first.text.strip
  #     [chin_pinyin,translation]
  #   }
  end


  def select_shortest(target, array)
    sorted = array.sort_by {|entry| entry[target].length }
    sorted[0]
  end


  def word_array(sentence)
    return sentence if sentence.kind_of?(Array)
    sentence.scan(/\w+/)
  end


  def word_string(arr)
    return arr  if arr.kind_of?(String)
    arr.join(' ')
  end

end





require 'csv'
raw_data = CSV.read('../spec/data/hsk.csv', :col_sep => '|', :encoding => 'utf-8')
puts "Raw data, size: #{raw_data.size}"
p raw_data.take(2)

hsk = HSK.new(raw_data)



# hash = to_hash(raw_data,
#                1 => :level,
#                2 => :number,
#                3 => :word_traditional,
#                4 => :word,
#                5 => :pinyin,
#                6 => :meaning,
#                7 => :tags)

no_tags = hsk.rows_with_empty_col(7)
puts "No tags: #{no_tags.size}."
# No tags: 664.
hsk.to_file('no_tags', no_tags, :col_sep => '|')

# hsk.add_tags(4, 7, [lambda {|word| if word.strip.size == 4 and !word.strip.match(/\s/) then "ideom" else nil end}])

no_tags = hsk.rows_with_empty_col(7)
puts "No tags: #{no_tags.size}."
# No tags: 492.

# p hsk.unique_words(7).keys

hsk.replace_words(7,
                  "pref" => "prefix",
                  "aux"  => "auxiliary",
                  "ono"  => "onomatope")

p hsk.unique_words(7).keys
# ["interjection", "particle", "adjective", "verb", "noun", "number",
#  "measure_word", "preposition", "adverb", "auxiliary", "pronoun", "conjugate", "prefix", "onomatope", "suffix"]

duplicates       = hsk.duplicate_words
merged           = hsk.merge_duplicate_words([7])


def check_merged_count(raw_data, duplicates, merged)
  original_size = raw_data.size
  merged_size   = merged.size
  unique_dups   = duplicates.keys.size
  total_dups    = duplicates.inject(0) {|sum,(word,freq)| sum + freq }
  to_be_removed = total_dups - unique_dups

  merged_size == original_size - to_be_removed
end

result = check_merged_count(raw_data, duplicates, merged)
puts "Merged count: "
if result
  p "OK"
else
  p "Not correct!"
end

former_duplicates = merged.select {|row|
  word = row[3]
  duplicates.include?(word)
}
p former_duplicates.take(2)
# [["hsk_1", "2", "啊", "啊", "a", "ah", ["interjection", "particle"]],
#  ["hsk_1", "141", "得", "得", "děi", "have to; be sure to", ["verb", "aux"]]]
p former_duplicates.size
# => 189


with_merged_cols = hsk.merge_cols([1], 7)
p with_merged_cols.take(2)
# [["hsk_1", "1", "啊", "啊", "ā", "ah", ["interjection", "hsk_1"]],
#  ["hsk_1", "2", "啊", "啊", "a", "ah", ["interjection", "particle", "hsk_1"]]]

hsk.to_file("hsk_computer_edited", hsk.data, :col_sep => '|')



# scraping

test_data = CSV.read('../spec/data/hsk_mini.csv', :encoding => 'utf-8')

hsk2 = HSK.new(test_data)
# hsk2.add_sentences_from('http://www.nciku.com/search/all/examples/{}', 4,
#                    :parent_css => 'div.examples_box > dl',
#                    #:sentence_css  => 'dt > span',
#                    :sentence_css  => '.pinyin',
#                    :translation_css => '.tc_sub')
# p hsk2.data


# 20000 HSK sentences data

require 'csv'

# hsk_20000 = CSV.read('../HSK/Word Lists/Old HSK Word Lists/HSK 20000 sentences deck/edit_with_ruby/hsk_facts.txt',
#                :encoding => 'utf-8', :col_sep => '|')
# p hsk_20000.take(2)
# [["他感冒了。", "He caught a cold.", "tā gǎn mào le。", "HSK1-limited1-part1"],
#  ["不用麻烦了。", "Don't bother.", "bù yòng má fan le。", "HSK1-limited1-part1"]]

unique_words = hsk.data.map {|row| row[3]}.uniq
p unique_words.take(10)

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


# ------------------------------------------------------------
puts "Starting testing..."
puts

words = ["我", "打", "他", "他们", "谁", "越 来越。。。"]

sentences = [['我打他。', 'tag'],                #  我，打，他
             ['他打我好疼。', 'tag'],            #  我，打，他
             ['他打谁？', 'tag'],                #      打，他，谁
             ['他们想知道你是谁。', 'tag'],      #          他，谁
             ['钱越来越多。', 'tag']]            #                ，越来越
# ------------------------------------------------------------

new_hsk = Chinese::HSK.new(1)

words = Chinese::HSK.unique_words(words)
p words

puts "With target word array:"
with_target_words = new_hsk.add_target_words(sentences, words)

p with_target_words
# [[[["我", "打", "他"], "我打他。"], "tag"],
#  [[["我", "打", "他"], "他打我好疼。"], "tag"],
#  [[["打", "他", "谁"], "他打谁？"], "tag"],
#  [[["他", "谁"], "他们想知道你是谁。"], "tag"],
#  [[["越 来越"], "钱越来越多。"], "tag"]]
puts

puts "Sorted by unique word count:"
sorted_by_unique_word_count = new_hsk.sort_by_unique_word_count(with_target_words)

p sorted_by_unique_word_count
# [[[["越 来越"], "钱越来越多。"], "tag"],
# [[["他", "谁"], "他们想知道你是谁。"], "tag"],
# [[["我", "打", "他"], "他打我好疼。"], "tag"],
# [[["打", "他", "谁"], "他打谁？"], "tag"],
# [[["我", "打", "他"], "我打他。"], "tag"]]
puts


puts "Add tag:"
sorted_with_tag = new_hsk.add_word_count_tag(sorted_by_unique_word_count)

p sorted_with_tag
# [[[["越 来越"], "钱越来越多。"], "tag", "unique_1"],
# [[["他", "谁"], "他们想知道你是谁。"], "tag", "unique_2"],
# [[["我", "打", "他"], "他打我好疼。"], "tag", "unique_3"],
# [[["打", "他", "谁"], "他打谁？"], "tag", "unique_3"],
# [[["我", "打", "他"], "我打他。"], "tag", "unique_3"]]
puts

puts "Minimum necessary sentences:"
minimum_sentences = new_hsk.minimum_necessary_sentences(sorted_with_tag, words)

p minimum_sentences
# [[[["我", "打", "他"], "我打他。"], "tag", "unique_3"],
# [[["谁"], "他打谁？"], "tag", "unique_3"],
# [[["越 来越"], "钱越来越多。"], "tag", "unique_1"]]
puts

puts "Remove unique words arrays:"
without_unique_word_arrays = new_hsk.remove_words_array(minimum_sentences)

p without_unique_word_arrays
# [["我打他。", "tag", "unique_3"],
#  ["他打谁？", "tag", "unique_3"],
#  ["钱越来越多。", "tag", "unique_1"]]
puts

test_result = new_hsk.contains_all_unique_words?(without_unique_word_arrays, words)
puts "Contains all unique words? => #{test_result}."


puts "To file:"
new_hsk.to_file('chinese_test.txt', without_unique_word_arrays, :col_sep => '|')


# puts
# puts "================================"
# puts "Real run"
# puts "================================"
#
# def time (&block)
#   start = Time.now
#   block.call if block
#   stop = Time.now
#   total = stop-start
#   puts "================================="
#   puts "Total time passed: #{total}."
# end
#
# time {
#   unique_words_source = CSV.read('./data/hsk_unique_words_source.csv', :encoding => 'utf-8', :col_sep => ',')
#   word_col            = Chinese::HSK.extract_column(unique_words_source, 4)
#   unique_words        = Chinese::HSK.unique_words(word_col)
#
#   data = CSV.read('./data/hsk_20000_chin_engl_pinyin.csv', :encoding => 'utf-8', :col_sep => '|')
#
#   hsk = Chinese::HSK.new(1)
#
#   with_target_words           = hsk.add_target_words_with_threads(data, unique_words)
#   sorted_by_unique_word_count = hsk.sort_by_unique_word_count(with_target_words)
#   sorted_with_tag             = hsk.add_word_count_tag(sorted_by_unique_word_count)
#   minimum_sentences           = hsk.minimum_necessary_sentences(sorted_with_tag, words)
#   without_unique_word_arrays  = hsk.remove_words_array(minimum_sentences)
#   hsk.to_file('hsk_20000_min_sentences.txt', without_unique_word_arrays, :col_sep => '|')
#
#
#   test_result = new_hsk.contains_all_unique_words?(without_unique_word_arrays, words)
#   puts "Contains all unique words? => #{test_result}."
# }
#
#
