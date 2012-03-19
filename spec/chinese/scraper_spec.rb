# encoding: utf-8

require 'spec_helper'

describe Chinese::Scraper do

  context "On success" do

    context :initialize do

      it "should not raise an exception" do  # Testing for errors for some reason does not work outside of 'it'.

        lambda do
          described_class.new("豆浆", :source => :nciku)
        end.should_not raise_error

        lambda do
          described_class.new("豆浆", :source => :jukuu)
        end.should_not raise_error
      end
    end

    context :sentences do

      context "Scraping nciku website" do

        let(:nciku) { described_class.new("豆浆", :source => :nciku )}

        specify { nciku.sentences.size.should == 1 }
        specify { nciku.sentences.should ==
                  [["新式的豆浆机配备了感应回水装置。",
                    "The new soybean milk machine is equipped with a inductive water-regurgitating setting."]] }
        specify { nciku.sentences.size.should == 1 }
      end

      context "Scraping the jukuu website" do

        let(:jukuu) { described_class.new("豆浆", :source => :jukuu )}

        specify { jukuu.sentences.size.should == 10 }
        specify { jukuu.sentences[0].should ==
                  ["他们能找到牛奶、鸡蛋、面包、甜点、巧克力、浓缩汤、蔬菜，甚至冰冻比萨和豆浆。",
                    "They find milk, eggs, bread and cookies, chocolate, soup, vegetables, even frozen pizzas and soymilk."] }
        specify { jukuu.sentences.size.should == 10 }
      end
    end

    context :sentence do

      # Using let(:scraper) {...} raises an error when setting the sentences:
      # undefined local variable or method `scraper' for #<Class:0x00000001028568> (NameError)
      scraper = described_class.new("豆浆", :source => :nciku )

      scraper.sentences = [["一","one"],["一二","one-two"],["一二三","one-three"],
                           ["一二三四","one-four"],["一二三四五","one-five"],["一二三四五六","one-six"]]

      # Actually the second smallest value is returned.
      specify {scraper.sentence(:size => :small).should  ==  ["一二","one-two"]}
      specify {scraper.sentence(:size => :middle).should == ["一二三","one-three"] }
      specify {scraper.sentence(:size => :large).should  == ["一二三四五六","one-six"] }
      # If no size specified, use :small as default
      specify {scraper.sentence                   ==  ["一二","one-two"]}

    end
  end


  context "On failure" do

    context :initialize do

      it "should raise an expection" do

        lambda do
          described_class.new("豆浆", :source => :not_supported)
        end.should raise_exception(ArgumentError, /'not_supported' is not a valid value for option :source/)

      end
    end


    context "When word is not found" do

      describe "Scraping the ncikuu website" do

        let(:nciku) { described_class.new("#$@", :source => :nciku )}

        specify { nciku.sentences.should be_empty }
      end

      describe "Scraping the jukuu website" do

        let(:jukuu) { described_class.new("#$@", :source => :jukuu )}

        specify { jukuu.sentences.should be_empty }
      end
    end

    context :sentence do

      describe "When an invalid option value is passed" do

        let(:scraper) {described_class.new("豆浆", :source => :nciku ) }

        it "should raise an exception" do

          lambda do
            scraper.sentence(:size => :not_supported)
          end.should raise_exception
        end
      end
    end
  end
end
