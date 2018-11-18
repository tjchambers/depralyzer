# frozen_string_literal: true

require 'depralyzer'
#
# RSpec Code Generator
#
module Depralyzer
  class Generator

    DEPRECATION_FORMAT = /DEPRECATION WARNING: .+?. \(called from .+?\)$/

    attr_accessor :input

    def initialize(input)
      @input = File.read(input)
    end

    def process
      warnings = input.scan(DEPRECATION_FORMAT)
      summary  = summarize warnings
      pretty_output summary
    end

    def pretty_output(summary)
      puts "Total of #{summary.size} deprecation types with #{occurrence(summary)} occurrences"
      m1 = summary.sort_by { |_, value| -value.values.inject(0) { |sum, x| sum + x } }.to_h
      m1.each do |top, details|
        puts
        puts "### #{top.gsub('_','\_')} (#{details.values.inject(0) { |sum, x| sum + x }})"

        annotation, new_details = deannotate(details)

        if annotation
          puts "##### #{annotation.gsub('_','\_')}"
        end
        
        m = new_details.sort_by { |_, value| -value }.to_h
        m.each do |note, cnt|
          puts sprintf("- %10d %s", cnt, note.gsub('_','\_'))
        end
      end
    end

    def deannotate(details)
      guess, _ = details.keys[0].split('. (', 2)
      new_details = {}
      details.each do |key, value|
        if key.start_with?(guess)
          _, rest =  key.split('. (', 2)
          new_details["(#{rest}"] = value
        else
          return [nil, details]
        end
      end
      [guess, new_details]
    end

    def occurrence(summary)
      i = 0
      summary.each do |_, detail|
        detail.each do |_, cnt|
          i += cnt
        end
      end
      i
    end

    def summarize(warnings)
      summary = {}
      warnings.each do |warning|
        content                = warning.sub('DEPRECATION WARNING: ', '')
        type, details          = content.split('. ', 2)
        summary[type]          = {} unless summary.key?(type)
        summary[type][details] = 0 unless summary[type].key?(details)
        summary[type][details] += 1
      end
      summary
    end
  end
end

