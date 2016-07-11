#!/usr/bin/ruby

require 'csv'
require 'date'

require 'iconv'

begin
  require 'rubygems'
  gem 'roo', '> 1.0.0'
  require 'roo'
rescue LoadError
  puts "ERROR: Cannot parse Excel files! Have you got the 'roo' gem?"
  raise
end

require 'dnbnor/dnbnor'

module DnBNOR


  ## 
  # Base class common to parsers.
  # 
  class ParserBase
    attr_reader :entries
    attr_reader :headers

    def initialize
      @entries = Array.new
    end

    def handle_row(row)
      entry = Entry.new
      row.each_with_index{|e,i|
        value = row[i]
        begin
          header = @headers[i]
          entry[@headers[i]] = massage_value(value)
        rescue StandardError => err
          puts "ERROR during parsing of row #{row}, field #{i}(#{header}) containing #{value}."
          p err
          p entry if DEBUG
        end
      }
      @entries << entry unless entry.empty?
    end

    def massage_value(value)
      value
    end


    ##
    # Select parser type based on file extension.
    # 
    def self.parser_type_from_file(input_file)
      case input_file
      when /\.csv$/i
        CSVParser
      when /\.txt$/i
        CSVParser
      when /\.xls$/i
        SpreadsheetParser
      when /\.xl[a-z]+$/i
        SpreadsheetParser
      else
        SpreadsheetParser
      end
    end
    
    ##
    # Create parser based on filename extension
    # and load the file.
    def self.load_from_file(input_file)
      parser_class = self.parser_type_from_file(input_file)
      dnb = parser_class.new
      dnb.load_file(input_file)
      return dnb
    end

  end


  ##
  # Simple DnBNOR transcript parser for the CSV format.
  #
  class CSVParser < ParserBase
    FIELD_SEPARATOR = "\t"

    def load_file( filename )
      File.open( filename, 'r' ){ |file|
        parse_data(file)
      }
    end

    def parse_data( data )               
      csv = CSV::Reader.create( data, "\t" )
      @headers = csv.shift
      p headers if DEBUG

      csv.each{|row| handle_row(row) }

      puts @entries if DEBUG      
    end

  end # CSVParser

  ##
  # Default format used to be CSV using tabs
  #
  ## Parser = CSVParser


  ##
  # Alternate DnBNOR transcript parser for the Excel format.
  #

  class SpreadsheetParser < ParserBase

    def load_file( filename )
      @inconv = Iconv.new("ISO-8859-15","UTF-8")

      file = Excel.new(filename)
      file.default_sheet = file.sheets.first # "Kontoutskrift" sheet
      parse_data(file)
    end

    def parse_data( data )
      @data = data
      @headers = data.row(data.first_row).collect{|v| massage_value(v) }

      p @headers if DEBUG

      (data.first_row+1).upto(data.last_row) do |ri|
        handle_row( data.row(ri) )
      end

      @data = nil
      puts @entries if DEBUG      
    end


    def massage_value(value)
      case value
      when String
        value = @inconv.iconv(value)
      end
      value
    end


  end # SpreadsheetParser


  ##
  # Default format now is Excel.
  #
  Parser = SpreadsheetParser




end
