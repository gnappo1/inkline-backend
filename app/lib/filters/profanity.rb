# app/lib/filters/profanity.rb
module Filters
  module Profanity
    module_function

    LEET = { "@"=>"a", "$"=>"s", "1"=>"i", "!"=>"i", "3"=>"e", "0"=>"o", "5"=>"s" }.freeze

    WHOLE_WORDS = %w[
      bitch bastard crap damn piss pussy asshole slut whore porn balls prick douche
      goddamn motherfucker bullshit jackass
    ].freeze

    STEMS_ANYWHERE = %w[
      fuck shit dick cock
    ].freeze

    WHOLE_WORD_REGEX = begin
      body = WHOLE_WORDS.map { Regexp.escape(_1) }.join("|")
      /\b(?:#{body})\b/i
    end

    STEMS_REGEX = begin
      body = STEMS_ANYWHERE.map { Regexp.escape(_1) }.join("|")
      /(#{body})/i
    end

    # normalize to compare apples-to-apples
    def base(text)
      text.to_s.downcase.tr(LEET.keys.join, LEET.values.join)
    end

    # punctuation → spaces (for whole-word)
    def with_spaces(text)
      base(text).gsub(/[^\p{Alnum}]+/, " ").squeeze(" ").strip
    end

    # punctuation removed (for stems like f.u.c.k → fuck)
    def joined(text)
      base(text).gsub(/[^\p{Alnum}]+/, "")
    end

    def blocked?(text)
      WHOLE_WORD_REGEX.match?(with_spaces(text)) || STEMS_REGEX.match?(joined(text))
    end
  end
end
