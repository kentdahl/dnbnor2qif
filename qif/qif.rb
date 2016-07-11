=begin
QIF - Quicken Interchange Format is an old, stale, de facto standard.

So we are just writing up the bits we need for importing the 
expenses.dat-file into other programs.

=end

##
#
module Qif
  

  ##
  #
  module QifEntry
    
    attr_accessor :name
    
    DEFAULT_FIELD_TYPES = 
      [
       # variable name, field code and formatting method
       [:@name, 'N'],
       [:@memo, 'M'],
       [:@description, 'D'],
       [:@date, 'D', :format_date],
       # [:@credit_acc, 'L'],
       [:@category,  'L'],
       [:@amount, 'T'],
       [:@account_type, 'T'],
       [:@payee, 'P'],
       [:@address, 'A', :format_address],       
       [:@cleared, 'C'],
       [:@num,     'N'],
    ]

    def field_types
      DEFAULT_FIELD_TYPES
    end


    ##
    # outputs the entry to the given IO.
    def output_to( o )
      o.puts "!#{header_name}"
      each_entry_type do |type|
        var_name, field, formatter = *type
        data = instance_variable_get( var_name )
        if data
          formatted_data = if formatter
                             self.send(formatter, data)
                           else
                             data
                           end
          o.puts "#{field}#{formatted_data}"
        end        
      end
      o.puts "^"
    end

    ## 
    # iterate through the entry fields applicable.
    def each_entry_type( &block )
      field_types.each &block
    end

    def header_name
      self.class.to_s.split(":").last
    end

    ##
    # Formats the date field for output to QIF.
    def format_date( date )
      sprintf "%02d-%02d-%04d", date.month, date.mday, date.year
    end

    ##
    # Formatting hack for address. 
    # Needed to wrap an array of address elements onto several lines.
    def format_address( address )
      return address.to_str if address.respond_to? :to_str
      address.join("\nA")
    end




  end

  class Account
    include QifEntry

    attr_reader :name, :type, :description
    def initialize(name, type = nil, description=nil)
      @name = name
      @type = type
      @description = description
    end    

    def to_s
      @name
    end
  end


  ##
  # The various types of transactions all go into Type.
  class Type
    include QifEntry

    QIF_TYPES = %w{Bank Cash CCard Invst}
    # Others: Oth A, Oth L, Cat, Class, Memorized 

    attr_accessor :date, :amount, :memo, :payee, :address, :num
    attr_accessor :debit_acc, :credit_acc

    ##
    # Valid type names.
    def initialize( type_name )
      QIF_TYPES.include?( type_name) or 
        raise ArgumentError, "Unsupported QIF type: #{type_name}."
      @type_name = type_name
    end

    attr_accessor :type_name

    def header_name
      "Type:#{@type_name}"
    end

  end

end



if __FILE__ == $0 then
  cash = Qif::Account.new( 'Wallet', 'My cash' ) 
  food = Qif::Account.new( 'Food',   'Grub'    )


  t = Qif::Type::new('Cash')
  t.date = Time.now
  t.debit_acc = food
  t.credit_acc = cash


  [cash,food,t].each{|i|
    i.output_to( $stdout )
  }
  

end

=begin
Sample QIF:


-----8<------
!Account
NEiendeler:Kontanter
DKontanter
^
!Type:Cash
D 07-28-2003
T -1024.59
M Legesjekk
L Buss
^
-----8<------
!Account
NUtgifter:Buss
^
!Type:Cash
D 07-28-2003
T 485
M Busskort
LEiendeler:Kontanter
^
-----8<------

=end
