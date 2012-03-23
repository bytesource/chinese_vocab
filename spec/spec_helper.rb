# encoding: utf-8
$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'csv'
require 'chinese/modules/options'
require 'chinese/scraper'
require 'chinese/vocab'


module HelperMethods

  def time (&block)
    start = Time.now
    block.call if block
    stop  = Time.now
    total = stop-start
  end
end


class Array


  # This does not work
  def rec_sort
     self.map do |x|
      if x.kind_of?(Array)
        x.rec_sort
      else
        [x]
      end
    end.sort_by {|x| x.length}
  end

  def array_of_arrays_equal?(arr)
    with_sorted_items1 = self.map(&:sort)
    with_sorted_items2 = arr.map(&:sort)
    with_sorted_items1.sort == with_sorted_items2.sort
  end
end



