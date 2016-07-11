require 'test/unit'
require 'qif/qif'

require 'stringio'

include Qif

class TestAccount < Test::Unit::TestCase
  def setup
    @io = StringIO.new
    @cash = Qif::Account.new( 'Wallet', nil, 'My cash' ) 
  end

  def test_account_output
    @cash.output_to( @io )
    assert_equal "!Account\nNWallet\nDMy cash\n^\n", @io.string
  end

  def test_transaction_output
    @food = Qif::Account.new( 'Food',   'Grub'    )
    t = Qif::Type::new('Cash')
    t.date = Time.at( 1059429288 )
    t.debit_acc = @food
    t.credit_acc = @cash
    t.output_to( @io )
    assert_equal "!Type:Cash\nD07-28-2003\n^\n", @io.string
  end

end




class TestQIFType < Test::Unit::TestCase
  def setup
    @cash = Qif::Type.new("Cash") 
    @bank = Qif::Type.new("Bank")
    @card = Qif::Type.new("CCard") 

  end

  def test_type_new
    assert( @cash )
    assert( @bank )
    assert( @card )
  end

  def test_type_fail
    assert_raises( ArgumentError ){ Qif::Type.new("Dinero") }
    assert_raises( ArgumentError ){ Qif::Type.new("Money") }
    assert_raises( ArgumentError ){ Qif::Type.new("Muchalucha") }
  end

end
