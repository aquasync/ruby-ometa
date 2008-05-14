require 'runtime'
require 'bootstrap'

def bootstrap_test
filename = 'ometa_translator.ometa'

puts "* reading grammar"
grammar = File.read(filename)

#puts grammar

puts "* parsing grammar into ast"
ast = OMetaParser.matchAllwith(grammar, 'grammar')

#p ast

puts "* translating into ruby"
str = RubyOMetaTranslator.matchwith(ast, 'trans')

#puts str

puts "* compiling into grammar object"
open('temp.rb', 'w') { |f| f << '$xxx1 = ' + str }
load 'temp.rb'
cls1 = $xxx1
#cls = eval str, binding

puts "* re-translating ast into ruby with new compiled grammar"
str2 = Cls1.matchwith(ast, 'trans')

puts "* re-compiling into grammar object"
open('temp2.rb', 'w') { |f| f << '$xxx2 = ' + str2 }
cls2 = eval str2, binding
#load 'temp2.rb'
#Cls2 = $xxx2

puts "* re-re-translating ast into ruby with new compiled grammar"
#p Cls2
str3 = Cls2.matchwith(ast, 'trans')

puts "* checking for equality"
raise unless str2 == str3

puts "* checking correct parse of calculator ast"
# now, with this class, which has bootstrapped itself, ensure it works
# note that this hasn't tested the grammar, only the translator. lets
# try a translated parser and see if that works

filename = 'ometa_parser.ometa'
grammar = File.read(filename)
ast = OMetaParser.matchAllwith(grammar, 'grammar')
str4 = Cls2.matchwith(ast, 'trans')
# so this is a dynamically built parser, build from the builtin parser, and
# a dynamically built translator built from a dynamic translator.
open('temp3.rb', 'w') { |f| f << '$xxx3 = ' + str4 }
cls3 = eval str4, binding
end

class Ometa
	def self.Grammar(filename)
		grammar = File.read(filename)
		ast = OMetaParser.parsewith(grammar, 'grammar')
		ruby = RubyOMetaTranslator.matchwith(ast, 'trans')
		#ruby = File.read('_debug.rb')
		begin
			open('_debug.rb', 'w') { |f| f << ruby }
			eval ruby
		rescue SyntaxError
			puts '* error compiling grammar'
			puts '* ast:'
			require 'pp'
			pp ast
			puts '* ruby:'
			puts ruby
			open('_debug.rb', 'w') { |f| f << ruby }
			raise
		end
	end
end

=begin
class Calc < Ometa::Grammar('calc.ometa')
	def self.calc str
		matchAllwith str, 'expr'
	end
end

p Calc
p Calc.calc('2^5^2')
p Calc.calc('(2^5)^2')
=end

class JSParser < Ometa::Grammar('js_parser.ometa')
	KEYWORDS = ["break", "case", "catch", "continue", "default", "delete", "do", "else", "finally", "for", "function", "if", "in",
            "instanceof", "new", "return", "switch", "this", "throw", "try", "typeof", "var", "void", "while", "with", "ometa"]

	KEYWORDS_HASH = KEYWORDS.inject({}) { |h, k| h.update k => true }

	def self._isKeyword k
		KEYWORDS_HASH[k.to_s]
	end
end

p JSParser.parsewith("  x  += 1;\n", 'expr')

