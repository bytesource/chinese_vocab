# encoding: utf-8
$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'csv'
require 'chinese_vocab/modules/helper_methods'
require 'chinese_vocab/scraper'
require 'chinese_vocab/vocab'


module HelperMethods

  def time(&block)
    start = Time.now
    block.call if block
    stop  = Time.now
    total = (stop-start)/60
    puts  "Time passed: #{total} minutes."
  end
end


class Array

  def array_of_arrays_equal?(arr)
    with_sorted_items1 = self.map(&:sort)
    with_sorted_items2 = arr.map(&:sort)
    with_sorted_items1.sort == with_sorted_items2.sort
  end
end



