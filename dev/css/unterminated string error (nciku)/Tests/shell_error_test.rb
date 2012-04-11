# encoding: utf-8
require 'string_to_pinyin'
cn = "烤成酥脆 [焦黑]"

hash = Hash.new
hash.merge!(cn: "hello_cn")
hash.merge!(py: cn.to_pinyin)
hash.merge!(en: "hello_en")

puts hash
# => {:cn=>"hello_cn", :py=>"kăo chéng sū cuì  [jiāo hēi ]", :en=>"hello_en"}


"'".to_pinyin
# sh: Syntax error: Unterminated quoted string
# => "'"
"'''".to_pinyin
# sh: Syntax error: Unterminated quoted string
# sh: Syntax error: Unterminated quoted string
# sh: Syntax error: Unterminated quoted string
# => "'''"

# {:word=>"抡", :chinese=>"He finished off his opponent with one swift swing with an axe.",
#  :pinyin=>"He finished off his opponent with one swift swing with an axeyī", :english=>"他一斧头抡下去干掉了对手。"}
# [{:word=>"嗯", :chinese=>"why, that's impossible!", :pinyin=>"why, that's impossible!", :english=>"嗯，那是不可能的！"}]
en = "why, that's impossible!"
# => "why, that's impossible!"
en.to_pinyin
# sh: Syntax error: Unterminated quoted string
# => "why, that's impossible!"

'"'.to_pinyin
# => "\""

"一次他向一个坐在树梢上把长长的尖镰刀抡向枝条的男孩高喊道：'当心点，别伤着椰枣树的心。'".to_pinyin
# sh: Syntax error: Unterminated quoted string
# sh: Syntax error: Unterminated quoted string
# => "yī cì tā xiàng yī gè zuò zài shù shāo shàng bă cháng cháng de jiān lián dāo lūn xiàng zhī tiáo de nán hái gāo hăn dào ：
#    'dāng xīn diăn ，bié shāng zhăo yé zăo shù de xīn 。'"

