# encoding: utf-8
require 'cgi'
require 'open-uri'
require 'nokogiri'
require 'core_ext/array'

module Chinese
  class Scraper

    attr_reader :source, :word


    Sources = {
      nciku:
      {:url         => "http://www.nciku.com/search/all/examples/",
       :parent_sel  => "div.examples_box > dl",
       :cn_sel      => "//dt/span[1]",
       :en_sel      => "//dd/span[@class='tc_sub']",
       :select_pair => lambda { |node1,node2| node1['class'] != "tc_sub" and node2['class'] == "tc_sub" },
       :first       => :cn,              # Sentences on the site are in the order Chinese first, translation second.
       :text_sel    => "text()"},
       jukuu:
       {:url         => "http://www.jukuu.com/search.php?q=",
        :parent_sel  => "table#Table1 table[width = '680']",
        :cn_sel      => "//tr[@class='c']",
        :en_sel      => "//tr[@class='e']",
        :select_pair => lambda { |node1,node2| node1['class'] == "e" and node2['class'] != "e" },
        :first       => :en,            # Sentences on the site are in the order translation first, Chinese second.
        :text_sel    => "td[2]"}
    }


    def initialize(source,word)
      if source_valid?(source)
        @source = source
      else
        raise ArgumentError, "'#{source}' is not a valid source. Please choose one of the following: #{default_sources.join(', ')}."
      end
      @word = word
    end


    # Options:
    # size => [:small, average, large], default = average
    def scrap_sentences
      source    = Sources[@source]
      url       = source[:url] + CGI.escape(@word)
      main_node = Nokogiri::HTML(open(url)).css(source[:parent_sel]) # Returns a single node.

      # CSS selector:   Returns the tags in the order they are specified
      # XPath selector: Return the tags in the order they appear in the document (that's what we want here).
      # Source:         http://stackoverflow.com/questions/5825136/nokogiri-and-finding-element-by-name/5845985#5845985
      target_nodes = main_node.search("#{source[:cn_sel]} | #{source[:en_sel]}")

      # In order to make sure we only return text that also has a translation,
      # we need to first group each target node with Array#overlap_pairs like this:
      # Input:  [cn1, cn2, en2, cn3, en3, cn4]
      # Output: [[cn1,cn2],[cn2,en2],[en2,cn3],[cn3,en3],[en3,cn4]]
      # and then select the correct pairs: [[cn2,en2],[cn3,en3]].
      # Regarding #to_a: Nokogiri::XML::NodeSet => Array
      sentence_pairs = target_nodes.to_a.overlap_pairs.select {|(node1,node2)| source[:select_pair].call(node1,node2) }
      # Switch position of each pair if the first entry is the translation.
      # (We always return an array of [cn_sentence,en_sentence] pairs.)
      sentence_pairs = sentence_pairs.map {|(node1,node2)| [node2,node1] }  unless source[:first] == :cn
      sentence_pairs = sentence_pairs.reduce([]) do |acc,(cn_node,en_node)|
        cn   = cn_node.css(source[:text_sel]).text.strip
        en   = en_node.css(source[:text_sel]).text.strip
        pair = [cn,en]
        acc << pair unless pair_with_empty_string?(pair)
        acc
      end

      sentence_pairs
    end


    # ===================
    # Helper functions
    # ===================


    def default_sources
      Sources.keys
    end

    def source_valid?(source)
      source = source.to_sym
      default_sources.include?(source)
    end

    def pair_with_empty_string?(pair)
      pair[0].empty? || pair[1].empty?
    end

    # Despite its name returns the SECOND shortest sentence,
    # as the shortest result often is not a real sentence,
    # but a definition.
    def shortest_size(sentence_pairs)
      sentence_pairs.sort_by {|(cn,_)| cn.length }.take(2).last
    end

    def longest_size(sentence_pairs)
      sentence_pairs.sort_by {|(cn,_)| cn.length }.last
    end

    def average_size(sentence_pairs)
      sorted = sentence_pairs.sort_by {|(cn,_)| cn.length }
      length = sorted.length
      sorted.find {|(cn,_)| cn.size >= length/2 }
    end


  end

end

