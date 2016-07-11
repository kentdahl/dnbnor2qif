#!/usr/bin/ruby
=begin
The command line program.
=end

$LOAD_PATH.push(File.dirname(__FILE__)) # Find my libs

require 'dnbnor/dnbnor_parser'

require 'qif/qif'

require 'iconv'
require 'stringio'


module DnBNOR

  module Converter

    class QIF

      def initialize( args )
        @args = args
        @outconv = Iconv.new("UTF-8","ISO-8859-15")

      end
      
      def command_convert
        input_file = @args['input']
        puts "Converting from file: #{input_file}"
        dnb = DnBNOR::Parser.load_from_file(input_file)
        @entries = dnb.entries

        puts "Loaded #{@entries.size} transactions."


        @bankaccount = Qif::Account.new( @args['account'],
                                         @args['account_type'] )

        @accounts = Hash.new
        @transactions = Array.new

        puts "Converting..."

        convert_entries
        # group_transactions

        puts "Outputing..."
        output_file = @args['output']
        File.open(output_file, 'w' ){|output|
          StringIO.open {|strio|
            output_to( strio )
            output << @outconv.iconv(strio.string)
          }
        }
        
        puts "Outputted to file: #{output_file}"

      end

      def convert_entries
        @entries.each do|e|
          p e if DEBUG

          # Then locate the payment account.
          if e.is_credit? then
            credit_acc = @bankaccount
            debit_acc  = nil
          elsif e.is_debit? then
            debit_acc = @bankaccount
            credit_acc  = nil
          else
            puts "ERROR: Problem with transaction, skipping."
            p e
            next
          end

          # Set up the QIF transaction.
          t = Qif::Type.new("Bank") 
          t.debit_acc  = debit_acc
          t.credit_acc = credit_acc

          # Fairly straight forward element assignment
          # Note that bank statement is inverse of our account view.
          t.amount = (e.is_credit? ? e.credit : -e.debit )
          t.memo   = e.details[:comment]
          t.date   = e.date
          t.num    = (e.details[:archive_id]     || 
                      e.details[:transaction_id] ||
                      e.details[:visa]           || 
                      nil)
          t.payee  = e.details[:payee]

          @transactions << t

        end

        ##
        # Group based on credit (asset) account.
        def group_transactions
          @grouped = Hash.new{ Array.new }
          unless @transactions 
            raise ArgumentError, "No data: Must convert first."
          end
          @transactions.each do |t|
            group = @grouped[ t.debit_acc ]
            group << t
            @grouped[ t.debit_acc] = group
          end
          @grouped
        end


        ##
        # Output QIF
        def output_to( io )
          @bankaccount.output_to( io )
          @transactions.each{|t|
            t.output_to( io )
          }
        end




      end


      USAGE = <<-EOD
Convert DnBNOR CSV to QIF.
Usage:
  ruby dnbnor2qif.rb -c [command] -i [input] [ -o [output] ]
Options:
  -c, --command   |- Command to execute, such as 'convert'.    
  -i, --input     |- Input file (CSV from DnBNOR) 
  -o, --output    |- Output filename (QIF) (optional)
  -a, --account   |- Full name of GnuCash bank account (optional)
  -d, --debug     |- Verbose debugging output (experimental)
EOD
      def command_help
        puts USAGE
      end
      
      
    end # QIF

  end # Converter
  
end # DnBNOR


if __FILE__ == $0 then
  require 'getoptlong'
  
  file = 'kontoutskrift.csv'
  arguments = {'command' => 'help', 
    'input' => file
  }
  opt = GetoptLong.new(
    ['--help',          '-h', GetoptLong::NO_ARGUMENT],
    ['--debug',         '-d', GetoptLong::NO_ARGUMENT],
    ['--input',         '-i', GetoptLong::REQUIRED_ARGUMENT],
    ['--output',        '-o', GetoptLong::REQUIRED_ARGUMENT],
    ['--command',       '-c', GetoptLong::REQUIRED_ARGUMENT],
    ['--account',       '-a', GetoptLong::REQUIRED_ARGUMENT]
  )

  opt.each{|opt,arg|
    s = /\-\-([a-z\-]*)/.match(opt)[1].to_s
    arguments[s] = arg
  }
  
  unless arguments['output'] || !arguments['input'] then
    arguments['output'] ||= arguments['input'] + ".qif"
  end

  # Dummy account name
  arguments['account'] ||= "DnB Nor bank account"

  DnBNOR::DEBUG = true if arguments['debug']

  command = DnBNOR::Converter::QIF.new( arguments )
  command.send( ('command_'+arguments['command']).intern )

end


