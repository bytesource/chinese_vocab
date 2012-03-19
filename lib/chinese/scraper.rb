# encoding: utf-8
require 'cgi'
require 'open-uri'
require 'nokogiri'
require 'core_ext/array'

module Chinese
  class Scraper

    attr_reader   :source, :word
    attr_accessor :sentences


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

    def option_specs
      {:source =>  {:validate  => lambda {|value| Sources.keys.include?(value) } ,
                    :default   => :nciku},
       :size   =>  {:validate  => lambda {|value| [:small, :middle, :large].include?(value) },
                    :default   => :small}}
    end


    def initialize(word, options={})
      @source = validate_option(:source, options)
      @word   = word
    end


    # Options:
    # size => [:small, average, large], default = average
    def sentences
      return @sentences  unless @sentences.nil?

      source    = Sources[@source]
      url       = source[:url] + CGI.escape(@word)
      main_node = Nokogiri::HTML(open(url)).css(source[:parent_sel]) # Returns a single node.
      return []  if main_node.to_a.empty?

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
        cn   = cn_node.css(source[:text_sel]).text.strip  # 'text' returns an empty string when 'css' returns an empty array.
        en   = en_node.css(source[:text_sel]).text.strip
        pair = [cn,en]
        # Ensure that both the chinese and english selector have text.
        # (sometimes they don't).
        acc << pair unless pair_with_empty_string?(pair)
        acc
      end

      @sentences = sentence_pairs
      @sentences
    end

    def sentence(options={})
      value = validate_option(:size, options)

      # Scrap sentences from website first if necessary.
      sentences         if sentences.nil?
      # Return directly if no sentences were found.
      return sentences  if sentences.empty?

      case value
      when :small
        shortest_size(@sentences)
      when :middle
        average_size(@sentences)
      when :large
        longest_size(@sentences)
      end
    end




    # ===================
    # Helper functions
    # ===================


    # Handling options:
    # Start

    def validate_option(key, options)
      # If key was not passed as a parameter, return its default value.
      return option_specs[key][:default]  unless options.has_key?(key)

      # Check validity of value
      value = options[key]
      test = option_specs[key][:validate].call(value)
      if test
        value
      else
        raise ArgumentError, "'#{value}' is not a valid value for option :#{key}."
      end
    end

    # Handling options
    # End

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

