require File.expand_path("lib/chinese_vocab/version")

Gem::Specification.new do |s|
  s.name        = "chinese_vocab"
  s.version     = Chinese::VERSION
  s.authors     = ["Stefan Rohlfing"]
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.description = <<-DESCRIPTION
===

This gem is meant to make live easier for any Chinese language student who:

* Prefers to learn vocabulary from Chinese sentences.
* Needs to memorize a lot of words on a _tight_ _time_ _schedule_.
* Uses the spaced repetition flashcard program {Anki}[http://ankisrs.net/].

Chinese::Vocab addresses all of the above requirements by downloading sentences for each word and
selecting the *minimum* *required* *number* *of* *Chinese* *sentences* (and English translations)
to *represent* *all* *words*.
DESCRIPTION
  s.summary               = 'Chinese::Vocab - Downloading and selecting the minimum required number of sentences to your Chinese vocabulary list'
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
