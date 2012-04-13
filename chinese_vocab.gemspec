require File.expand_path("lib/with_validations/version")

Gem::Specification.new do |s|
  s.name        = "chinese_vocab"
  s.version     = WithValidations::VERSION
  s.authors     = ["Stefan Rohlfing"]
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.description = <<-DESCRIPTION

DESCRIPTION
  s.summary               = 'Chinese::Vocab - Adding the minimum required number of sentences to your Chinese vocabulary list'
  s.email                 = 'stefan.rohlfing@gmail.com'
  s.homepage              = 'http://github.com/bytesource/chinese_vocab'
  s.has_rdoc              = 'yard'
  s.required_ruby_version = '>= 1.9.1'
  s.rubyforge_project     = 'chinese_vocab'

  s.add_dependency 'with_validations'
  s.add_dependency 'nokogiri'
  s.add_dependency 'string_to_pinyin'

  s.add_development_dependency 'rspec'

  s.files = Dir["{lib}/**/*.rb", "*.md", 'Rakefile', 'LICENSE', 'Gemfile']
end
