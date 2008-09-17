
__END__

#
# later on the idea is to add a Ometa::Grammar function or something similar to wrap
# up the process of creating a ruby class object from an ometa grammar file.
#
# as an example (this is missing the optimization pass):
#
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

class Calc < Ometa::Grammar('calc.ometa')
	def self.calc str
		matchAllwith str, 'expr'
	end
end

class JSParser < Ometa::Grammar('js_parser.ometa')
	KEYWORDS = ["break", "case", "catch", "continue", "default", "delete", "do", "else", "finally", "for", "function", "if", "in",
            "instanceof", "new", "return", "switch", "this", "throw", "try", "typeof", "var", "void", "while", "with", "ometa"]

	KEYWORDS_HASH = KEYWORDS.inject({}) { |h, k| h.update k => true }

	def self._isKeyword k
		KEYWORDS_HASH[k.to_s]
	end
end

p JSParser.parsewith("  x  += 1;\n", 'expr')

