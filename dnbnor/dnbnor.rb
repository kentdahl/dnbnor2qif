=begin

DnBNOR simple accounting data.

=end


require 'date'

module DnBNOR

  DEBUG = false

  ##
  # Single transaction entry from.
  class Entry 

    FIELD_MAP = {
      # Norwegian
      "Dato"         => :date, 
      "Forklaring"   => :details, 
      "Rentedato"    => :interest_date, 
      "Ut fra konto" => :debit,
      "Inn på konto" => :credit,

      # Norwegian variations
      "Ut av konto" => :debit,
      "Inn til konto" => :credit,

      # English
      "Date (mm.dd.yyyy)" => :date, 
      "Description"       => :details, 
      "Interest date"     => :interest_date, 
      "Withdrawals"       => :debit,
      "Deposits"          => :credit,

    }

    AMOUNT_RE = /(\d+[,.]?\d*)/
    DATE_FORMAT = "%d.%m.%y"

    def initialize
      @data = Hash.new
    end

    def []=(index, value)
      key = FIELD_MAP[index]||index
      @data[ key ] = parse_value( key, value )
    end

    def method_missing( sym, *args )
      @data[sym]
    end

    def parse_value( key, value )
      # p [key, value] if DEBUG
      return nil unless value # No value? Nothing we can do.
      case key
      when :date, :interest_date
        return value if value.kind_of?(Date)
        ( value ? Date.strptime(value, DATE_FORMAT) : nil )
      when :debit, :credit
        return value if value.kind_of?(Numeric) 
        ( value =~ AMOUNT_RE ? $1.tr(',','.').to_f : nil )
      when :details
        parse_details( value.chomp.gsub(/\s{2,}/, " ").tr("\n"," ").strip )
      else
        value
      end
    end

    def parse_details( details )
      c = Hash.new

      case details

      when /^Varekj.p\s+(\d+)\s+\,?Ark\.ref\s+\*(\d+)\s+Dato\s+(\d+\.\d+)\s+Kl\.\s+(\d+\.\d+)\s+Versjon\s+\d+\s+Aut\.\s+(\d+)\s+(.*)$/
        c[:type] = :purchase
        c[:date] = $3 # TODO: parse_value( :date, $3 )
        c[:time] = $4.tr('.',':')
        c[:transaction_id] = $1.to_i
        c[:archive_id] = $2.to_i
        c[:authentication_id] = $5.to_i
        c[:comment] = $6

      when /^(L.nn)\s+(\d+)\s+\,?Fra\s+(.*?)\s*$/
        c[:comment] = $1
        c[:archive_id]     = $2.to_i
        c[:payee]   = $3

      when /^Visa\s+(\d+)\s+\,?(.*?)\s*$/
        c[:type] = :visa
        c[:visa] = $1
        c[:comment] = $2 + " (Visa)"        

      when /^(Overføring [InUt]+land)\s+(\d+)\s+(.*?)\s*$/
        c[:archive_id] = $2.to_i
        c[:comment]        = $3 + " (#{$1})"
      when /^(Giro)\s+(\d+)\s+(.*?)\s*$/
        c[:archive_id] = $2.to_i
        c[:comment]        = $3 + " (#{$1})"


      # when /^Kontoregulering/
      # when /^Lønn/
      # when /^Omkostninger/

      when /^(Reservert\s+\-\s+ikke\s+Bokført)\s*$/
        # Should be ignored?
        

      when /^,(.*?)\s*$/
        # Old DnB Nor CSV comment format
        c[:comment] = $1

      when /^\s*(.*?)\s+Betnr\:\s+(\d+)\s*$/i
        # Postbanken, payment number.
        c[:comment] = $1
        c[:archive_id] = $2.to_i

      when /^([^,]+),(.*?)\s*$/
        c[:comment] = "#{$2} (#{$1})"

      else
        c[:comment] = details

      end

      c
    end

    def parse_purchase_details( details )

    end

    def is_debit?
      debit && debit > 0
    end

    def is_credit?
      credit && credit > 0
    end

    def empty?
      @data.empty? || @data.all?{|key,val| val.nil?}
    end

    def to_s
      "<#{@data[:date]} #{@data[:credit]} #{@data[:debit]} \n\t'#{@data[:details].inspect}' >"
    end

  end

end # DnBNOR
