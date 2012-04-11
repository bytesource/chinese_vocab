# encoding: utf-8
require 'spec_helper'

describe Chinese::Vocab do

  context :full_run do
    words = Chinese::Vocab.parse_words('../../hsk_data/word_lists/old_hsk_level_8828_chars_1_word_edited.csv', 4)

    anki = Chinese::Vocab.new(words, :compact => true)

    all_words = anki.words
    puts "Number of distinct words: #{all_words.size}"

    File.open('all_words_edited', 'w') do |f|
      f.puts all_words
    end
    puts "Saved edited words to file."

    sentences = anki.min_sentences(:size => :average, :source => :nciku, :with_pinyin => true, :thread_count => 8)
    anki.to_csv('in_the_wild_test.csv')
    puts "Contains all words?: #{anki.contains_all_target_words?(sentences, :chinese)}."
    puts "Missing words (@not_found): #{anki.not_found}"
    puts "Number of unique characters in sentences: #{anki.sentences_unique_chars.size}"
  end

end
# sentences = anki.min_sentences(:size => :average, :source => :nciku, :with_pinyin => true, :thread_count => 16)
# #contains_all_target_words?
# Words not found:
# ["定阅", "独立自主", "蛾子", "发奋图强", "烦闷", "反革命", "防汛", "分化", "分批", "风沙", "复辟", "概况", "搞活", "稿纸", "各奔前程", "各别", "工事", "攻关", "公分", "关切", "规格", "国际主义", "汉奸", "汉学", "航运", "好样的", "浩浩荡荡", "禾苗", "贺词", "狠毒", "红领巾", "混纺", "机车", "坚贞不屈", "检举", "简要", "建交", "界文艺界", "锦绣", "进程", "就地", "军医", "开天辟地", "可歌可泣", "口岸", "来回来去", "来看来讲", "老成", "连带", "练兵", "粮票", "流寇", "路子", "没吃没穿", "勉励", "排队", "品行", "七嘴八舌", "千军万马", "前赴后继", "勤工俭学", "山冈", "山沟", "山岭", "商榷", "晌午", "审定", "深美", "肾炎", "时事", "实体", "试制", "手巾", "书面", "私有制", "探头探脑", "桃花", "逃荒", "提要", "天长地久", "通报", "偷税", "外向型", "万水千山", "唯心论", "问答", "无情无意", "下放", "下台", "先前", "新陈代谢", "叙谈", "压韵", "烟卷", "要领", "一技之长", "饮水思源", "蝇子", "榆树", "沾光", "照会", "这么着", "真是的", "争气", "正巧", "政协", "职能", "指手划脚", "中游", "重心", "主人翁", "转向"]
# -----------------------------
# Contains all words?: false.
# Missing words (@not_found): ["定阅", "独立自主", "蛾子", "发奋图强", "烦闷", "反革命", "防汛", "分化", "分批", "风沙", "复辟", "概况", "搞活", "稿纸", "各奔前程", "各别", "工事", "公分", "攻关", "规格", "关切", "国际主义", "汉奸", "汉学", "航运", "好样的", "浩浩荡荡", "狠毒", "禾苗", "贺词", "红领巾", "混纺", "机车", "坚贞不屈", "检举", "简要", "建交", "界文艺界", "进程", "锦绣", "就地", "开工", "开天辟地", "军医", "可歌可泣", "口岸", "来回来去", "老成", "来看来讲", "连带", "练兵", "粮票", "流寇", "路子", "没吃没穿", "勉励", "排队", "品行", "七嘴八舌", "气力", "千军万马", "前赴后继", "勤工俭学", "山沟", "山冈", "山岭", "商榷", "晌午", "审定", "深美", "肾炎", "时事", "实体", "试制", "手巾", "书面", "私有制", "探头探脑", "桃花", "逃荒", "提要", "天长地久", "通报", "偷税", "外向型", "万水千山", "唯心论", "问答", "无情无意", "下台", "下放", "先前", "新陈代谢", "叙谈", "压韵", "烟卷", "要领", "一技之长", "饮水思源", "蝇子", "用具", "榆树", "沾光", "照会", "这么着", "真是的", "争气", "正巧", "政协", "职能", "指手划脚", "中游", "重心", "主人翁", "转向"]
# Number of unique characters in sentences: 3225
