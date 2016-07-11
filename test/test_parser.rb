=begin

Test cases for DnBNOR (tm) CSV and Excel data file parsing.

=end


require 'test/unit'
require 'stringio'
require 'dnbnor/dnbnor_parser'

class TestDnBNORCSVParser < Test::Unit::TestCase
  def setup
    @parser = DnBNOR::CSVParser.new
  end

  ENTRIES_TC0 = "Dato	Forklaring	Rentedato	Ut fra konto	Inn på konto
08.08.07	Varekjøp  45451919               ,Ark.ref *769769769 Dato 08.08 Kl. 11.19 Versjon 1 Aut. 24642     Kiwi Sannergata Sannergt.3 Oslo	08.08.07	79,70	0,00
27.07.07	Visa  101010                       ,Norgestaxi AS 	01.08.07	560,00	0,00
06.08.07	Giro  201                          ,Talkmore AS Nettgiro M/kid	06.08.07	1500,00	0,00
18.08.07	Overføring Innland  22112233     ,Kent Dahl 	28.08.07	0,00	20000,00"


  def test_entries_tc0
    @parser.parse_data( ENTRIES_TC0 )
    helper_check_test_entries
  end


  def helper_check_test_entries
    assert_equal( 4, @parser.entries.size )

    e = @parser.entries[0]
    assert_equal( "2007-08-08", e.date.to_s )
    assert_equal( "2007-08-08", e.interest_date.to_s )
    assert_equal( 79.70, e.debit )   # Banks have their transcript account...
    assert_equal( 0,     e.credit )  # ...backwards towards our view.
    c = e.details
    assert_equal( :purchase,  c[:type] )
    assert_equal( 45451919,   c[:transaction_id])
    assert_equal( 769769769,  c[:archive_id])
    assert_equal( 24642,      c[:authentication_id])
    assert_equal( "08.08",   c[:date])
    assert_equal( "11:19",   c[:time])
    assert_equal( "Kiwi Sannergata Sannergt.3 Oslo",   c[:comment])


    e = @parser.entries[1]
    assert_equal( "2007-07-27", e.date.to_s )
    assert_equal( "2007-08-01", e.interest_date.to_s )
    assert_equal( 0,      e.credit )
    assert_equal( 560.00, e.debit  )
    c = e.details
    assert_equal( :visa,  c[:type] )
    assert_equal( "Norgestaxi AS (Visa)",   c[:comment])



    e = @parser.entries[2]
    assert_equal( "2007-08-06", e.date.to_s )
    assert_equal( "2007-08-06", e.interest_date.to_s )
    assert_equal( 0,    e.credit )
    assert_equal( 1500, e.debit  )

    e = @parser.entries[3]
    assert_equal( "2007-08-18", e.date.to_s )
    assert_equal( "2007-08-28", e.interest_date.to_s )
    assert_equal( 20000, e.credit)
    assert_equal( 0,     e.debit)
    
  end


  def test_entries_with_english_headers
    entries = ENTRIES_TC0.dup.split("\n")
    entries.shift
    entries.unshift("Date (mm.dd.yyyy)	Description	Interest date	Withdrawals	Deposits")
    
    @parser.parse_data( entries.join("\n") )
    helper_check_test_entries
  end


  def test_entries_with_alternate_norwegian_headers
    entries = ENTRIES_TC0.dup.split("\n")
    entries.shift
    entries.unshift("Dato	Forklaring	Rentedato	Ut av konto	Inn til konto")
    
    @parser.parse_data( entries.join("\n") )
    helper_check_test_entries
  end


  ENTRIES_TC1 = "Dato	Forklaring	Rentedato	Ut fra konto	Inn på konto
08.08.07	Varekjøp  45451919               ,Ark.ref *769769769 Dato 08.08 Kl. 11.19 Versjon 1 Aut. 24642     Kiwi Sannergata Sannergt.3 Oslo	08.08.07	79,70	0,00

"
  def test_entries_blanks
    @parser.parse_data( ENTRIES_TC1 )
    assert_equal( 1, @parser.entries.size )
  end


  ENTRIES_TC2 = "Dato	Forklaring	Rentedato	Ut fra konto	Inn på konto
08.08.07		08.08.07	79,70	0,00

"

  def test_entries_blank_description
    @parser.parse_data( ENTRIES_TC2 )
    assert_equal( 1, @parser.entries.size )
    # nil is by design until we see missing descriptions in the wild.
    assert_nil( @parser.entries.first.details )
  end



end



class TestDnBNORSpreadsheetParser < Test::Unit::TestCase

  def setup
    @parser = DnBNOR::SpreadsheetParser.new
    @parser.load_file("test/data/simple1.xls")
  end

  def test_loading_headers
    assert_equal( 5,      @parser.headers.size )
    assert_equal( "Dato", @parser.headers.first )
    assert_equal( "Inn på konto", @parser.headers.last )
  end

  def test_entries_
    assert_equal( 4, @parser.entries.size )

    assert_equal( 4, @parser.entries.size )

    e = @parser.entries[0]
    assert_equal( "2007-09-10", e.date.to_s )
    assert_equal( "2007-09-12", e.interest_date.to_s )
    assert_equal( 1345, e.debit )   
    assert_equal( 0,    e.credit )  
    c = e.details
    assert_equal( :purchase,  c[:type] )
    assert_equal( 9988776655,   c[:transaction_id])
    assert_equal( 1928374655,  c[:archive_id])
    assert_equal( 918273645,      c[:authentication_id])
    assert_equal( "12.09",   c[:date])
    assert_equal( "14:15",   c[:time])
    assert_equal( "Duty Free -TEST-",   c[:comment])

    e = @parser.entries[1]
    assert_equal( 48.13, e.debit )   

    e = @parser.entries[2]
    assert_equal( 15123, e.credit )   

  end

end

##
# Reuse above tests for the CSV version as well.
#
class TestDnBNORCSVParserFromFile < TestDnBNORSpreadsheetParser

  def setup
    @parser = DnBNOR::CSVParser.new
    @parser.load_file("test/data/simple1.csv")
  end

end


class TestFoo < Test::Unit::TestCase
  def test_foo
    assert_kind_of( DnBNOR::CSVParser, 
                    DnBNOR::Parser.load_from_file("test/data/simple1.csv") )
    assert_kind_of( DnBNOR::SpreadsheetParser, 
                    DnBNOR::Parser.load_from_file("test/data/simple1.xls") )
    assert_equal(DnBNOR::CSVParser, 
                 DnBNOR::Parser.parser_type_from_file("nonexistant/file.TXT"))
    assert_equal(DnBNOR::CSVParser, 
                 DnBNOR::Parser.parser_type_from_file("nonexistant/file.TXT"))
    assert_equal(DnBNOR::SpreadsheetParser, 
                 DnBNOR::Parser.parser_type_from_file("nonexistant/file.XLS"))
    assert_equal(DnBNOR::SpreadsheetParser, 
                 DnBNOR::Parser.parser_type_from_file("nonexistant/file.XLA"))
    assert_equal(DnBNOR::SpreadsheetParser, 
                 DnBNOR::Parser.parser_type_from_file("nonexistant/file.XLfoo"))
    assert_equal(DnBNOR::SpreadsheetParser, 
                 DnBNOR::Parser.parser_type_from_file("nonexistant/file.xzy"))
    
  end
end

