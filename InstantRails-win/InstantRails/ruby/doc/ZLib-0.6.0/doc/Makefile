RD2 = rd2
RUBY = ruby
RM = rm -f

all: rd html

rd: zlib.rd zlib.rd.ja
html: zlib.html zlib.ja.html

clean:
	@$(RM) zlib.rd zlib.rd.ja
	@$(RM) zlib.html zlib.ja.html

zlib.rd: zlib.rd.src langsplit.rb
	$(RUBY) langsplit.rb -en $< > $@
zlib.rd.ja: zlib.rd.src langsplit.rb
	$(RUBY) langsplit.rb $< > $@

zlib.html: zlib.rd
	$(RD2) $< > $@
zlib.ja.html: zlib.rd.ja
	$(RD2) $< > $@
