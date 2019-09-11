require 'parslet'
require 'singleton'

module Parsers

  class LaLorraine
    include Singleton

    attr_reader :parser, :transformer

    def initialize
      @header_parser = HeaderParser.new
      @header_interpreter = HeaderInterpreter.new
      @lines_parser = LinesParser.new
      @lines_interpreter = LinesInterpreter.new
    end

    def parse(string)
      # Since a header can appear more than once, we look for all appearances
      # and replace them with empty strings
      header_string = string.lines.first(10).join
      lines_string = string.split(header_string).map(&:strip).join("\n").strip

      output = @header_interpreter.apply(@header_parser.parse(header_string))

      output.merge!(order_lines: [],
                    unmatched:   [],
                    driver_code: '00',
                    addition:    false,
                    delivery:    '')

      lines = @lines_interpreter.apply(@lines_parser.parse(lines_string))

      lines.each do |line|
        if line[:unmatched_line]
          output[:unmatched] << line[:unmatched_line]
        elsif line[:order_line]
          output[:order_lines] << line[:order_line]
        elsif line[:last_line]
          output.merge!(line[:last_line])
        elsif line[:extra]
          output[:extra] = line[:extra]
        end
      end

      output

    rescue => e
      raise Parslet::ParseFailed, "Some error happened while parsing. #{e.message}"
    end

    class GenericParser < Parslet::Parser

      rule :digit do
        match['0-9']
      end

      rule :spaces do
        str(' ').repeat(1)
      end

      rule :number do
        digit.repeat(1)
      end

      rule :nl do
        match['\n']
      end

      rule :not_nl do
        nl.absent? >> any
      end

      rule :date do
        digit.repeat(2,2) >> str('.') >>
        digit.repeat(2,2) >> str('.') >>
        digit.repeat(4,4)
      end

      # any 4 lines
      rule :address do
        not_nl.repeat >> nl >>
            not_nl.repeat >> nl >>
            not_nl.repeat >> nl >>
            not_nl.repeat
      end

    end

    class HeaderParser < GenericParser
      rule :header do
        number >> nl >>
            date.as(:date) >> nl >> nl >>
            address.as(:address) >> nl >> nl >>
            number >> nl >> nl
      end

      root :header
    end

    class LinesParser < GenericParser

      rule :article_number do
        (digit | str('-')).repeat(1)
      end


      rule :order_line do
        article_number.as(:article_number)  >> spaces >>
            number.as(:count) >> spaces >>
            not_nl.repeat.as(:description)
      end

      rule :ignored_line do
        str('L') | str('H') >> spaces >> str('1')
      end

      rule :last_line do
        str('B') >> digit.repeat(2,2).as(:driver_code) >>
            (str('-') >> digit.repeat(2,2)).maybe >>
            spaces >> str('1') >> spaces >>
            not_nl.repeat.as(:description)
      end

      rule :extra do
        str('--- EKSTRA ---') >> nl >> any.repeat.as(:extra)
      end

      rule :unmatched_line do
        not_nl.repeat(1).as(:error)
      end

      rule :any_line do
        ignored_line | extra |
            last_line.as(:last_line) |
            order_line.as(:order_line) |
            unmatched_line.as(:unmatched_line)
      end

      rule :lines do
        any_line >> (nl.repeat(1) >> any_line).repeat
      end

      root(:lines)
    end

    class HeaderInterpreter < Parslet::Transform
      rule date: simple(:date), address: simple(:address) do
        { date: Date.parse(date.to_s), address: address.to_s.gsub(/\n\n/, "\n") }
      end
    end

    class LinesInterpreter < Parslet::Transform

      rule(
          article_number: simple(:article_number),
          count:          simple(:count),
          description:    simple(:description)
      ) do
        { article_number: article_number.to_s,
          count:          count.to_s.to_i,
          description:    description.to_s
        }
      end

      rule(
          driver_code: simple(:driver_code),
          description: simple(:description)
      ) do
        desc = description.to_s
        { driver_code: driver_code.to_s,
          addition:    desc.ends_with?('TILLÆG'),
          delivery:    desc.gsub(/TILLÆG$/, '').strip
        }
      end

      rule(extra: simple(:extra)) do
        { extra: extra.to_s.strip }
      end

      rule(error: simple(:text)) do
        text.to_s
      end

      rule(error: []) do
        ''
      end

    end

  end

end
