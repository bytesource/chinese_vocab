# encoding: utf-8
require 'cgi'
require 'open-uri'
require 'nokogiri'
require 'chinese/core_ext/array'
require 'chinese/modules/options'

module Chinese
  class Scraper
    include Options

    attr_reader   :source, :word
    attr_accessor :sentences

    Sources = {
    nciku:
    {:url         => "http://www.nciku.com/search/all/examples/",
     :parent_sel  => "div.examples_box > dl",
     :cn_sel      => "//dt/span[1]",
     :en_sel      => "//dd/span[@class='tc_sub']",
                     # Only cn/en sentence pairs where the second node has a class 'tc_sub' belong together.
     :select_pair => lambda { |node1,node2| node1['class'] != "tc_sub" && node2['class'] == "tc_sub" },
                     # Just return the text stored in the node. :text_sel is mainly intended for jukuu (see below)
     :text_sel    => "text()",
                     # We want cn first, en second, but nciku does not return cn/en sentence pairs in a strict order.
     :reorder     => lambda { |text1,text2| if is_unicode?(text2) then [text2,text1] else [text1,text2] end }},
     jukuu:
     {:url         => "http://www.jukuu.com/search.php?q=",
      :parent_sel  => "table#Table1 table[width = '680']",
      :cn_sel      => "//tr[@class='c']",
      :en_sel      => "//tr[@class='e']",
                     # Only cn/en sentence pairs where the first node has a class 'e' belong together.
      :select_pair => lambda { |node1,node2| node1['class'] == "e" && node2['class'] != "e" },
      :text_sel    => "td[2]",
      :reorder     => lambda { |text1,text2| [text2,text1] }}
  }

  OPTIONS =  {:source =>  [:nciku,  lambda {|value| Sources.keys.include?(value) }],
              :size   =>  [:average, lambda {|value| [:short, :average, :long].include?(value) }]}


    # Options:
    # size => [:short, :average, :long], default = :average
    def self.sentences(word, options={})
      download_source = validate { :source }

      source = Sources[download_source]

      CGI.accept_charset = 'UTF-8'
      # Note: Use + because << changes the object on its left hand side, but + doesn't:
      # http://stackoverflow.com/questions/377768/string-concatenation-and-ruby/378258#378258
      url       = source[:url] + CGI.escape(word)
      main_node = Nokogiri::HTML(open(url)).css(source[:parent_sel]) # Returns a single node.
      return []  if main_node.to_a.empty?

      # CSS selector:   Returns the tags in the order they are specified
      # XPath selector: Return the tags in the order they appear in the document (that's what we want here).
      # Source:         http://stackoverflow.com/questions/5825136/nokogiri-and-finding-element-by-name/5845985#5845985
      target_nodes = main_node.search("#{source[:cn_sel]} | #{source[:en_sel]}")
      return [] if target_nodes.to_a.empty?

      # In order to make sure we only return text that also has a translation,
      # we need to first group each target node with Array#overlap_pairs like this:
      # Input:  [cn1, cn2, en2, cn3, en3, cn4]
      # Output: [[cn1,cn2],[cn2,en2],[en2,cn3],[cn3,en3],[en3,cn4]]
      # and then select the correct pairs: [[cn2,en2],[cn3,en3]].
      # Regarding #to_a: Nokogiri::XML::NodeSet => Array
      sentence_pairs = target_nodes.to_a.overlap_pairs.select {|(node1,node2)| source[:select_pair].call(node1,node2) }
      sentence_pairs = sentence_pairs.reduce([]) do |acc,(cn_node,en_node)|
        cn   = cn_node.css(source[:text_sel]).text.strip  # 'text' returns an empty string when 'css' returns an empty array.
        en   = en_node.css(source[:text_sel]).text.strip
        pair = [cn,en]
        # Ensure that both the chinese and english selector have text.
        # (sometimes they don't).
        acc << pair unless pair_with_empty_string?(pair)
        acc
      end
      # Switch position of each pair if the first entry is the translation,
      # as we always return an array of [cn_sentence,en_sentence] pairs.
      # The following step is necessary because:
      # 1) Jukuu returns sentences in the order English first, Chinese second
      # 2) Nciku mostly returns sentences in the order Chinese first, English second
      #    (but sometimes it is the other way round.)
      sentence_pairs = sentence_pairs.map {|node1,node2| source[:reorder].call(node1,node2) }

      sentence_pairs
    end

    def self.sentence(word, options={})
      value = validate { :size }

      scraped_sentences = sentences(word, options)
      return [] if scraped_sentences.empty?

      case value
      when :short
        shortest_size(scraped_sentences)
      when :average
        average_size(scraped_sentences)
      when :long
        longest_size(scraped_sentences)
      end
    end


    # ===================
    # Helper functions
    # ===================

    # def self.is_unicode?(word)
    #   puts "Unicode check..."
    #   # Remove all non-ascii and non-unicode word characters
    #   word = distinct_words(word).join
    #   # English text at this point only contains characters that are mathed by \w
    #   # Chinese text at this point contains mostly/only unicode word characters that are not matched by \w.
    #   # In case of Chinese text the size of 'char_arr' therefore has to be smaller than the size of 'word'
    #   char_arr = word.scan(/\w/)
    #   char_arr.size < word.size
    # end

    # # Input: "除了。。。 以外。。。"
    # # Outout: ["除了", "以外"]
    # def self.distinct_words(word)
    #   # http://stackoverflow.com/a/3976004
    #   # Alternative: /[[:word:]]+/
    #   word.scan(/\p{Word}+/)      # Returns an array of characters that belong together.
    # end

    def self.pair_with_empty_string?(pair)
      pair[0].empty? || pair[1].empty?
    end

    # Despite its name returns the SECOND shortest sentence,
    # as the shortest result often is not a real sentence,
    # but a definition.
    def self.shortest_size(sentence_pairs)
      sentence_pairs.sort_by {|(cn,_)| cn.length }.take(2).last
    end

    def self.longest_size(sentence_pairs)
      sentence_pairs.sort_by {|(cn,_)| cn.length }.last
    end

    def self.average_size(sentence_pairs)
      sorted = sentence_pairs.sort_by {|(cn,_)| cn.length }
      length = sorted.length
      sorted.find {|(cn,_)| cn.size >= length/2 }
    end



  end
end

