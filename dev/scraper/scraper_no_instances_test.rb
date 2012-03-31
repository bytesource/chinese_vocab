# encoding: utf-8
lib = '../../lib'
require_relative File.join(lib, 'chinese/core_ext/array')
require_relative File.join(lib, 'chinese/modules/options')
require_relative 'scraper_no_instances'

Chinese::Scraper.sentences("豆浆", :source => :jukuu)

p Chinese::Scraper.sentence("豆浆",
                            :source => :jukuu,
                            :size   => :small)
# ["有时我们喝牛奶或豆浆。", "Sometimes we have milk or soybean milk."]

