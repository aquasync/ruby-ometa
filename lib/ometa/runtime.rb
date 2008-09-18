UNDEFINED = Object.new

class Fail < StandardError
	attr_accessor :matcher
	attr_accessor :failPos
end

class Character < String
	undef_method :each if ''.respond_to?(:each)

	class StringWrapper
		include Enumerable

		def initialize str
			@str = str
		end

		def length
			@str.length
		end

		def [] i
			Character.new @str[i..i]
		end

		def each
			length.times { |i| yield self[i] }
		end

		def to_s
			@str.to_s
		end

		def inspect
			@str.inspect
		end
	end

	# make them display with single quotes
	def inspect
		"'" + super[1..-2] + "'"
	end
end

class Stream
	def copy
		self
	end
end

class ReadStream < Stream
	attr_reader :pos
	def initialize obj
		if String === obj
#			puts 'note, wrapping string in a string wrapper'
			obj = Character::StringWrapper.new obj
		end
		@src = obj
		@pos = 0
	end

	def eof?
		@pos >= @src.length
	end

	def next
		@src[@pos]
	ensure
		@pos += 1
	end
end

class LazyStream < Stream
	def self.new head, tail, stream
		if stream and stream.eof?
			LazyInputStreamEnd.new stream
		else
			LazyInputStream.new head, tail, stream
		end
	end
end

class LazyInputStream < Stream
	attr_reader :memo
	def initialize head=UNDEFINED, tail=UNDEFINED, stream=nil
		@head = head
		@tail = tail
		@stream = stream
		@memo = {}
	end

	def head
		if @head == UNDEFINED
			@head = @stream.next
		end
		@head
	end

	def tail
		if @tail == UNDEFINED
			@tail = LazyStream.new UNDEFINED, UNDEFINED, @stream
		end
		@tail
	end

	# also interesting, due to backtracking, would possibly be to store
	# @stream.pos in initialize, which would presumably be the actual stream
	# pos at which any potential error occurred.
	def realPos
		@stream.pos
	end
end

class LazyInputStreamEnd < Stream
	attr_reader :memo

	def initialize stream
		@stream = stream
		@memo = {}
	end

	def realPos
		@stream.pos
	end

	def head
		#throw :fail, true #raise Fail #EOFError
		raise Fail
	end

	def tail
		raise NoMethodError
	end
end

class LazyStreamWrapper < Stream
	attr_reader :memo, :stream
	def initialize stream
		@stream = stream
		@memo = {}
	end

	def realPos
		@stream.pos
	end

	def head
		@stream.head
	end

	def tail
		self.class.new @stream.tail
	end
end

class LeftRecursion
	attr_accessor :detected
end

#// the OMeta "class" and basic functionality
#// TODO: make apply support indirect left recursion

class OMeta
	attr_reader :input

	def _apply(rule)
		#p rule
		memoRec = @input.memo[rule]
		if not memoRec
			oldInput = @input
			lr = LeftRecursion.new
			@input.memo[rule] = memoRec = lr
			# should these be copies too?
			@input.memo[rule] = memoRec = {:ans => method(rule).call, :nextInput => @input}
			if lr.detected
				sentinel = @input
				while true
					begin
						@input = oldInput
						ans = send rule
						raise Fail if @input == sentinel
						oldInput.memo[rule] = memoRec = {:ans => ans, :nextInput => @input}
					rescue Fail
						break
					end
				end
			end
		elsif LeftRecursion === memoRec
			memoRec.detected = true
			raise Fail #throw :fail, true
		end
		@input = memoRec[:nextInput]
		return memoRec[:ans]
	end

	def _applyWithArgs(rule, *args)
		#p :app_wit_arg => [rule, args]
		args.reverse_each do |arg|
			@input = LazyStream.new arg, @input, nil
		end
		send rule
	end

	def _superApplyWithArgs(rule, *args)
		#for (var idx = arguments.length - 1; idx > 1; idx--)
		#  $elf.input = makeOMInputStream(arguments[idx], $elf.input, null)
		#return this[rule].apply($elf)
		# would probably be easier to use realsuper in the caller, rather than do this
		##classes = self.class.ancestors.select { |a| Class === a }
		#methods = classes.map { |a| a.instance_method rule rescue nil }.compact
		#method = methods.first.bind(self)
		args.reverse_each do |arg|
			@input = LazyStream.new arg, @input, nil
		end
		# we leverage the inbuild ruby super, by means of the block passed to this function
		# which calls super
		yield
		#method.call
	end

	def _pred(b)
		if (b)
			return true
		end
		raise Fail
	end

	def _xnot
		oldInput = @input.copy
		begin
			yield
		rescue Fail
			@input = oldInput
			return true
		end
		raise Fail
	end

	def _xlookahead
		oldInput = @input.copy
		r = yield
		@input = oldInput
		r
	end

	def _or(*args)
		oldInput = @input.copy
		args.each do |arg|
			begin
				@input = oldInput
				return arg.call
			rescue Fail
			end
		end
		raise Fail
	end

	def _xmany(*ans)
		while true
			oldInput = @input.copy
			begin
				ans << yield
				next
			rescue Fail
			end
			@input = oldInput
			break
		end
		ans
	end

	def _xmany1(&block)
		_xmany block.call, &block
	end

	def _xform
		v = _apply "anything"
		raise Fail unless v.respond_to? :each
		oldInput = @input
		@input = LazyStream.new UNDEFINED, UNDEFINED, ReadStream.new(v)
		r = yield
		_apply "end"
		@input = oldInput
		v
	end

	#// some basic rules
	def anything
		r = @input.head
		@input = @input.tail
		return r
	end

	def end 
		_xnot { _apply("anything") }
	end

	def empty
		return true
	end

	def apply
		_apply _apply('anything')
	end

	def foreign
		g   = _apply("anything")
		r   = _apply("anything")
		fis = LazyStreamWrapper.new @input
		gi = g.new(fis)
		ans = gi._apply(r)
		@input = gi.input.stream
		#p :foreign => ans
		return ans
	end

	#//  some useful "derived" rules
	def exactly
		wanted = _apply("anything")
		if wanted == _apply("anything")
			return wanted
		end
		raise Fail #throw :fail, true
	end

	def char
		r = _apply("anything")
		_pred(Character === r)
		return r
	end

	def space
		r = _apply("char")
		_pred(r[0] <= 32)
		return r
	end

	def spaces
		_xmany { _apply("space") }
	end

	def digit
		r = _apply("char")
		_pred(r =~ /[0-9]/)
		return r
	end

	def lower
		r = _apply("char")
		_pred(r =~ /[a-z]/)
		return r
	end

	def upper
		r = _apply("char")
		_pred(r =~ /[A-Z]/)
		return r
	end

	def letter
		_or(
				proc { _apply 'lower' },
				proc { _apply 'upper' })
	end

	def letterOrDigit
		_or(
				proc { _apply 'letter' },
				proc { _apply 'digit' })
	end

	def firstAndRest
		first = _apply 'anything'
		rest = _apply 'anything'
		_xmany(_apply(first)) { _apply rest }
	end

	def seq
		xs = _apply 'anything'
		if String === xs
			xs = Character::StringWrapper.new xs
		end
		xs.each { |obj| _applyWithArgs 'exactly', obj }
		xs
	end

	def notLast
		rule = _apply("anything")
		r    = _apply(rule)
		_xlookahead { _apply(rule) }
		return r
	end

	def initialize(input)
		@input = input
		initialize_hook
	end
	
	def initialize_hook
	end

	# #match:with: and #matchAll:with: are a grammar's "public interface"
	def self.genericMatch(input, rule, *args)
		m = new(input)
		e = nil
		begin
			if args.empty?
				return m._apply(rule)
			else
				return m._applyWithArgs(rule, *args)
			end
		rescue Fail
			e = $!
		end
		#e = Fail.new
		e.matcher = m
		e.message.replace "Unable to match at pos #{m.input.instance_variable_get(:@stream).pos.inspect}"
		raise e
	end

	def self.matchwith(obj, rule, *args)
		genericMatch LazyStream.new(UNDEFINED, UNDEFINED, ReadStream.new([obj])), rule, *args
	end

	def self.matchAllwith(listyObj, rule, *args)
		genericMatch LazyStream.new(UNDEFINED, UNDEFINED, ReadStream.new(listyObj)), rule, *args
	end

	# ----

	def listOf
		rule  = _apply("anything")
		delim = _apply("anything")
		_or(proc {
			r = _apply(rule)
			_xmany(r) {
				_applyWithArgs("token", delim)
				_apply(rule)
				}
			},
			proc { [] }
		)
	end

	def token
		cs = _apply("anything")
		_apply("spaces")
		return _applyWithArgs("seq", cs)
	end

	def parse
		rule = _apply("anything"),
		ans  = _apply(rule)
		_apply("end")
		return ans
	end

	NICER_FAILURE_METHODS = {
		'_or' => 'No matching alternative',
		nil => 'Failure'
	}

	def self.parsewith(text, rule)
		begin
			return matchAllwith(text, rule)
		rescue Fail => e
			e.failPos = e.matcher.input.realPos() - 1
			cause = NICER_FAILURE_METHODS[$@.first[/`(.*?)'/, 1]] || NICER_FAILURE_METHODS[nil]
			rule = $@.find { |l| l !~ /runtime/ }[/`(.*?)'/, 1]
			lines = text[0, e.failPos].to_a
			lines = [''] if lines.empty?
			message = "#{cause} in rule #{rule.inspect}, at line #{lines.length} character #{lines.last.length + 1}"
			raise e, message #, $@
		end
	end

	ESCAPE_LOOKUP = {'n' => "\n", 't' => "\t", 'r' => "\r", '\'' => "'", '\"' => '"', '\\' => '\\'}

	def unescapeChar c
		ESCAPE_LOOKUP[c] or raise NotImplementedError
	end
end

