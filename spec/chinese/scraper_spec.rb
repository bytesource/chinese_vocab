# encoding: utf-8

require 'spec_helper'

describe Chinese::Scraper do

  let(:scraper) { described_class }
  let(:word)    { "豆浆" }

  context "On success" do

    # context :initialize do

    #   it "should not raise an exception" do  # Testing for errors for some reason does not work outside of 'it'.

    #     lambda do
    #       described_class.new("豆浆", :source => :nciku)
    #     end.should_not raise_error

    #     lambda do
    #       described_class.new("豆浆", :source => :jukuu)
    #     end.should_not raise_error
    #   end
    # end

    context :sentences do

      context "Scraping nciku website" do

        # defaults:
        # :source = :nciku
        specify { scraper.sentences(word).size.should == 1 }
        specify { scraper.sentences(word, :source => :nciku).should ==
                  [["新式的豆浆机配备了感应回水装置。",
                    "The new soybean milk machine is equipped with a inductive water-regurgitating setting."]] }
        specify { scraper.sentences(word, :source => :nciku).size.should == 1 }
      end

      context "Scraping the jukuu website" do

        specify { scraper.sentences(word, :source => :jukuu).size.should == 10 }
        specify { scraper.sentences(word, :source => :jukuu)[0].should ==
                  ["他们能找到牛奶、鸡蛋、面包、甜点、巧克力、浓缩汤、蔬菜，甚至冰冻比萨和豆浆。",
                    "They find milk, eggs, bread and cookies, chocolate, soup, vegetables, even frozen pizzas and soymilk."] }
        specify { scraper.sentences(word, :source => :jukuu).size.should == 10 }
      end
    end

    context :sentence do

      result = [["一","one"],["一二","one-two"],["一二三","one-three"],
                                  ["一二三四","one-four"],["一二三四五","one-five"],["一二三四五六","one-six"]]


      # Actually the second smallest value is returned.
      specify do
        scraper.stub(:sentences) { result }
        scraper.sentence(word, :source => :nciku, :size => :small).should  == ["一二","one-two"]
      end
      specify do
        scraper.stub(:sentences) { result }
        scraper.sentence(word, :source => :nciku, :size => :middle).should == ["一二三","one-three"]
      end
      specify do
        scraper.stub(:sentences) { result }
        scraper.sentence(word, :source => :nciku, :size => :large).should  == ["一二三四五六","one-six"]
      end

      # If no size specified, use :small as default
      specify {scraper.sentence(word)  ==  ["一二","one-two"]}

    end

    context :pair_with_empty_string?

    specify { scraper.pair_with_empty_string?(["hello", "world"]).should be_false }
    specify { scraper.pair_with_empty_string?(["", "world"]).should be_true }
    specify { scraper.pair_with_empty_string?(["", ""]).should be_true }
  end


  context "On failure" do

    # context :initialize do

    #   it "should raise an expection" do

    #     lambda do
    #       described_class.new("豆浆", :source => :not_supported)
    #     end.should raise_exception(ArgumentError, /'not_supported' is not a valid value for option :source/)

    #   end
    # end


    context "When word is not found" do

      let(:no_word) { "#$@" }

      describe "Scraping the nciku website" do

        specify { scraper.sentences(no_word, :source => :nciku).should be_empty }
        # defaults:
        # :source = :nciku
        # :size   = small
        specify { scraper.sentence(no_word, :source => :nciku).should be_empty }   # sentence
      end

      describe "Scraping the jukuu website" do

        specify { scraper.sentences(no_word, :source => :jukuu).should be_empty }
      end
    end

    context :sentence do

      describe "When an invalid option value is passed" do

        it "should raise an exception" do

          lambda do
            scraper.sentence(word, :source => :not_valid)
          end.should raise_exception

          lambda do
            scraper.sentence(word, :source => :jukuu, :size => :not_supported)
          end.should raise_exception
        end
      end
    end
  end
end
