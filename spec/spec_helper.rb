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


