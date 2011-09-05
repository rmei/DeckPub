# encoding: utf-8

class Deck
  attr_reader :options, :cards, :columns
  def self.d(o)
    #p o
  end

=begin
Card_Order
  => 1 | 2

Font_Size
  => M | L | X

Font_Name
  => String | nil

Text_Colors => (Float Float Float Float) | nil
  all: Float
  red: Float
  green: Float
  blue: Float

TTS => Int (0 or 4, here)

Layout_Index => 1 | 2

Layout_String => NameString ':' Card_Layout[5|] '||' Card_Layout[5|]

Card_Layout => Text_Format ( ',' Text_Format )x4 ',' Picture_Format ',' Sound_Format

Text_Format => ( T{index} [ ' ' {scale} ] ) | nil
  index: Int [1-5]
  scale: Float

Picture_Format => ( P{index} ) | nil

Sound_Format => ( S{index} ) | nil

  *	layout-string	Simple Modular:T1,,,,,P1,S1|T1,T2 2,,,,P2,S2|T3 1.2,T4,,,,P3,S3|,,,,,,|,,,,,,||T1,,,,,P1,|T3 1.2,T4,,,,P2,S5|T1,T2 2,,,,P3,|,,,,,,|,,,,,,|||Custom 2:T1,,,,,P1,S1|T2,,,,,P2,S2|T3,,,,,P3,S3|T4,,,,,P4,S4|T5,,,,,P5,S5||T2,,,,,P2,S2|T1,,,,,P1,S1|T3,,,,,P3,S3|T4,,,,,P4,S4|T5,,,,,P5,S5

Deck_Options
  name: string
  notes: string
  author: string
  card-order: 1|2
  font-size: Font_Size[5,]
  font:  (Font_Name as String)[5,]
  text-colors:  Text_Colors[5,]
  tsv:  boolean
  card-layout: Layout_Index
  layout-string: Layout_String[2 ||| ]
  category-1: String[N|]
  category-2: String[N|]
  category-3: String[N|]
  category-4: String[N|]
=end
  def self.handleOption(key, str)
    if key =~ /^(?:name|notes|author|card-order|tsv|card-layout)$/
      return str
    elsif key =~ /^(?:font-size|font|text-colors|tts-voice)$/
      return ArrayString.from str
    elsif key =~ /^(?:layout-string)$/
      return ArrayString.from(str, "|||") {|s| Custom_Layout.new(s)}
    elsif key =~ /^category-\d$/
      return ArrayString.from str, "|"
    else
      p key
      raise Exception
    end
  end

  def initialize(options, columns, cards)
    @options = options
    @columns = columns
    @cards = cards
  end

  def self.load(io)
    # get opts
    d io
    options = {}
    while (l=io.readline) =~ /^\*/
      x,key,val = l.chomp.split /\t/
      options[key] = handleOption(key, val)
    end

    # get column headers
    columns = l.chomp.split(/\t/)
    d columns

    # get rows
    text=io.read
    cards = []
    line = []
    while text.length > 0
      text.sub! /^("(?:[^"]|"")*"|(?:[^\n"\t]*(?<!\r)))(?=\t|(?:\r?\n))/ , ""
      l = $1
      d $1; d text.length
      l.gsub! /^"((?:[^"\n\r])*)"$/, "$1"
      l.sub!(/^(.*)$/, $1) if l =~ /^[^"].*[\n\r].*[^"]$/
      line.push l
      d text if text.length < 30
      if text.sub!(/^\r?\n/ , "") or text.length==0
        d line
        cards.push Card.new(columns, line)
        line = []
      else
        text.sub! /^\t/, ""
      end
    end
    cards.push Card.new(columns, line) if line.length > 0

    Deck.new(options, columns, cards)
  end
  #public_class_method:load

  def render(io)
    @options.each { |k, v| io.print "*\t#{k}\t#{v.to_s}\r\n" }
    io.print @columns.join("\t"), "\r\n"
    io.print @cards.map { |card| card.render(@columns) }.join("\r\n")
  end

end

class Card
  attr_reader :text, :picture, :sound, :category
  attr_accessor :notes

  def render(headers)
    headers.map { |header|
      name, i = parse_header header
      bucket = instance_variable_get name
      bucket = [bucket] if name == :@notes
      bucket[i]
    }.join("\t")
  end

  def initialize(headers, fields)
    buckets = {}
    max = 0;
    headers.zip(fields).each do |header, field|
      name, i = parse_header header
      #p name, i
      if name==:@notes
        buckets[name]=field
      else
        buckets[name]||=[]
        buckets[name][i]=field
        max = [max, i].max unless name == :@category
      end
    end
    @max = max
    buckets.each_pair {|k,v| instance_variable_set k, v}
  end

  private

  def parse_header(column_header)
    column_header =~ /(\S+)(?: (\d))?/
    name = "@#{$1.downcase}".to_sym
    i=$2; i||="1"; i=i.to_i-1
    return name, i
  end
end

class Custom_Layout
  attr_accessor :name
  attr_reader :side1, :side2
  def initialize(str)
    str = str.sub /^([^:]+):/, ""
    @name=$1
    s1, s2 = str.split "||"
    @side1 = ArrayString.from(s1, "|") {|s| Card_Layout.new(s)}
    @side2 = ArrayString.from(s2, "|") {|s| Card_Layout.new(s)}
  end
  def to_s; "#{@name}:#{@side1}||#{@side2}"; end;
end

class Card_Layout
  attr_accessor :picture, :sound
  attr_reader :text
  def initialize(str)
    slots = str.split ",", -1
    @sound = slots.pop
    @picture = slots.pop
    @text = ArrayString.as(5, ",")
    (1..5).each{|i| @text[i] = slots.shift}
  end
  def to_s; "#{@text},#{@picture},#{@sound}"; end
end

class ArrayString
  attr_reader :backing_array
  attr_accessor :delimiter, :size

  def length; @backing_array.length; end

  def self.from(str, delimiter=",")
    items = str.split delimiter, -1
    items.map!{|s| yield s} if block_given?
    return ArrayString.new(items, items.length, delimiter)
  end

  def self.as(size, delimiter=",")
    return ArrayString.new([], size, delimiter)
  end

  def initialize(items, size, delimiter)
    @delimiter = delimiter
    @backing_array = items
    @size = size
  end

  def to_s; @backing_array.join @delimiter; end

  def []=(i, val) ; check i; @backing_array[i-1] = val ; end
  def [](i) ;       check i; @backing_array[i-1]; end

  private
  def check(i); raise Exception if i > @size or i < 1; end
end
