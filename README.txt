 ____________________________________________________
|                                                    |
|            *** DNBNOR-TO-QIF ***                   |
|____________________________________________________|

 dnbnor2qif is a simple tool to help integrate data from the 
   DnBNOR online bank monthly transcripts ("kontoutskrift")
     to a QIF accepting financial program, i.e. GnuCash.

                  Kent Dahl 
            <kentda AT pvv DOT org>

              Copyright 2007-2008
         Released under the Ruby license.

Available from:
          http://dnbnor2qif.rubyforge.org/
          http://rubyforge.org/projects/dnbnor2qif/
          http://www.pvv.org/~kentda/ruby/
 
____________________________________________________
Disclaimer:

This is an experimental hack and you may end up bankrupt or worse
if you try to rely on its correct functioning. You have been warned.

This program is in no way, what so ever, implied or otherwise, endorsed by
nor affiliated with DnB NOR (https://www.dnbnor.no/). You should really go
bug them about providing OFX downloads directly instead.

____________________________________________________
Contents of this document:

- Requirements
- How to use
- Plans for the future
- Related links
- Other alternatives

____________________________________________________
Requirements:

* Ruby 1.8.x or newer
  -- http://www.ruby-lang.org/

* roo 1.0.1 or newer
  -- http://roo.rubyforge.org/
  -- To install: gem install roo


____________________________________________________
How to use dnbnor2qif:

First download the bank statement from the online bank site:
- Click on "Totaloversikt" and select the account.
- Click on the "Kontoutskrift" tab and fetch the month you want.
- Right-click on "Kopier til regneark" link and save the document.

Then run the script from the command line:
  ruby dnbnor2qif.rb -c [command] -i [input] [ -o [output] ]

Options:
  -c, --command   |- Command to execute, such as 'convert'.
  -i, --input     |- Input file (CSV from DnBNOR)
  -o, --output    |- Output filename (QIF) (optional)
  -a, --account   |- Full name of GnuCash bank account (optional)
  -d, --debug     |- Verbose debugging output (experimental)


____________________________________________________
Plans for the future:

See the TODO.txt file.


____________________________________________________
Related links:

* expenses2qif for the Agenda VR3
  -- http://agtoys.sourceforge.net/ruby/

* qif/qif.rb
  -- very simple QIF writer.

____________________________________________________
Other potential alternatives:

* MT2OFX
  -- http://www.xs4all.nl/~csmale/mt2ofx/en/

* XL2QIF
  -- http://xl2qif.chez-alice.fr/xl2qif_en.php

* QIF Master 
  -- (for MacOS X only)
  -- http://www.thewoodwards.us/sw/QIFMaster/

* MnyBank
  -- http://ferraroa.dyndns.org:8200/MnyBank/help/doc.htm

____________________________________________________
