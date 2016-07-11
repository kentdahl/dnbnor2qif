=begin

Test cases for DnBNOR (tm) data file parsing.

=end


require 'test/unit'
require 'dnbnor/dnbnor.rb'

class TestDnBNOR < Test::Unit::TestCase
  def setup
    @entry = DnBNOR::Entry.new
  end

  def test_parse_value_date
    assert_equal( "1978-05-25", @entry.parse_value(:date, "25.05.78").to_s)
    assert_equal( "2007-06-05", @entry.parse_value(:date, "05.06.07").to_s)
    assert_equal( "2000-12-31", @entry.parse_value(:interest_date, "31.12.00").to_s)
    assert_equal( nil, @entry.parse_value(:interest_date, nil))

  end

  def test_parse_value_amount
    assert_equal(  256.99, @entry.parse_value(:credit, "256,99") )
    assert_equal(  512.78, @entry.parse_value(:debit,  "512.78") )
    assert_equal( 1512.78, @entry.parse_value(:debit,  "1512.78") )
  end


  DETAILS_TC1 = "Varekjøp  55551111               ,Ark.ref *17171717 Dato 08.08 Kl. 11.19 Versjon 1 Aut. 12345     Kiwi Sannergata Sannergt.3 Oslo"
  DETAILS_TC2 = "Visa  112233                       ,Kr.sand Parkeringsselskap        "
  def test_parse_details

    c = @entry.parse_details( DETAILS_TC1 )
    assert_equal( :purchase,  c[:type] )
    assert_equal( 55551111,  c[:transaction_id])
    assert_equal( 17171717,  c[:archive_id])
    assert_equal( 12345,     c[:authentication_id])
    assert_equal( "08.08",   c[:date])
    assert_equal( "11:19",   c[:time])
    assert_equal( "Kiwi Sannergata Sannergt.3 Oslo",   c[:comment])

    c = @entry.parse_details( DETAILS_TC2 )
    assert_equal( :visa,  c[:type] )
    assert_equal( "Kr.sand Parkeringsselskap (Visa)",   c[:comment])

  end


  def test_parse_no_description
    c = @entry.parse_details( nil )
    assert_not_nil c
  end

  def test_empty_entry
    assert_equal( true, @entry.empty? )

    @entry['Dato'] =  nil
    assert_equal( true, @entry.empty? )

  end

end


class TestPostbanken < Test::Unit::TestCase
  def setup
    @entry = DnBNOR::Entry.new
  end


  def test_posbanken_payment_number
    c = @entry.parse_details("FAST OPPDR. FOND POSTBANKEN NORGE        Betnr:  561     ")
    assert_equal( 561, c[:archive_id] )
    assert_equal( "FAST OPPDR. FOND POSTBANKEN NORGE", c[:comment] )

    c = @entry.parse_details("AVTALEGIRO       NextGenTel AS           BETNR: 0562     ")
    assert_equal( 562, c[:archive_id] )
    assert_equal( "AVTALEGIRO       NextGenTel AS", c[:comment] )

  end


end



