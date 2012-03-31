 # encoding: utf-8
lib = '../../lib'
require_relative File.join(lib, 'chinese/core_ext/array')
require_relative File.join(lib, 'chinese/modules/options')
require_relative 'scraper_bug_fix'

scraper = Chinese::Scraper.new("豆浆", :source => :jukuu)

p scraper.sentence
# ["有时我们喝牛奶或豆浆。", "Sometimes we have milk or soybean milk."]

