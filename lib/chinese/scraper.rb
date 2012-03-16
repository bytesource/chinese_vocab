# encoding: utf-8
require 'open-uri'
require 'nokogiri'

module Chinese
  class HSK

    Selectors = {:nciku =>
                 {:parent_sel => "div.examples_box > dl",
                  :cn_sel     => "//dt/span[1]",
                  :en_sel     => "//dd/span[@class='tc_sub'",
                  :en_class   => "tc_sub",
                  :sub_sel    => "text()"},
                 :jukuu =>
                 {:parent_sel => "table#Table1 table[width = '680']",
                  :cn_sel     => "//tr[@class='c']",
                  :en_sel     => "//tr[@class='e']",
                  :en_class   => "e",
                  :sub_sel    => "td[2]"}}


    def scrap_sentences(source, options={})

    end
  end

end

