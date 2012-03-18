# encoding: utf-8

require 'spec_helper'

describe Chinese::Scraper do


  context "On success" do

    context :initialize do

      it "should not raise an exception" do

        lambda do
          described_class.new(:nciku, "豆浆")
        end.should_not raise_error
      end
    end


    describe "Scraping the ncikuu website" do

      let(:nciku) { described_class.new(:nciku, "豆浆" )}

      context :scrap_sentences do

        specify { nciku.scrap_sentences.size.should == 1 }
        specify { nciku.scrap_sentences.should ==
                  [["新式的豆浆机配备了感应回水装置。",
                    "The new soybean milk machine is equipped with a inductive water-regurgitating setting."]] }
      end
    end

    context "On failure" do


      context :initialize do

        it "should raise an expection" do

          lambda do
            described_class.new(:not_supported, "豆浆")
          end.should raise_exception(ArgumentError, /'not_supported' is not.*?nciku, jukuu/)

        end
      end

      let(:nciku) { described_class.new(:nciku, "豆浆" )}
    end
  end
end
