require 'runtime'

class String
	def toProgramString
		inspect
	end
end

class BSRubyParser < OMeta
def rt
	self
end

	def eChar
	return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("exactly","\\");c=rt._apply("char");return eval("\"\\" + c + "\"")}).call}),(proc{return (proc{return rt._apply("char")}).call}))}).call}))
	end

	def tsString
	return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("exactly","\'");xs=rt._many(proc{return rt._or((proc{return (proc{rt._not(proc{return rt._applyWithArgs("exactly","\'")});return rt._apply("eChar")}).call}))});rt._applyWithArgs("exactly","\'");return xs.join("")}).call}))}).call}))
	end

	def expr
		spaces
		tsString
	end

	def semAction
		spaces
		_many(proc { 
			_not proc { _applyWithArgs 'seq', "\n" }
			anything
		}).join
	end
end

class BSRubyTranslator < OMeta
	def trans
		anything
	end
end

class OMetaParser < OMeta
def rt
	self
end

def nameFirst
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{return rt._applyWithArgs("exactly","_")}).call}),(proc{return (proc{return rt._applyWithArgs("exactly","$")}).call}),(proc{return (proc{return rt._apply("letter")}).call}))}).call}))
end

def nameRest
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{return rt._apply("nameFirst")}).call}),(proc{return (proc{return rt._apply("digit")}).call}))}).call}))
end

def tsName
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{xs=rt._applyWithArgs("firstAndRest","nameFirst","nameRest");return xs.join("")}).call}))}).call}))
end

def name
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._apply("spaces");return rt._apply("tsName")}).call}))}).call}))
end

def eChar
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("exactly","\\");c=rt._apply("char");return eval("\"\\" + c + "\"")}).call}),(proc{return (proc{return rt._apply("char")}).call}))}).call}))
end

def tsString
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("exactly","\'");xs=rt._many(proc{return rt._or((proc{return (proc{rt._not(proc{return rt._applyWithArgs("exactly","\'")});return rt._apply("eChar")}).call}))});rt._applyWithArgs("exactly","\'");return xs.join("")}).call}))}).call}))
end

def characters
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("exactly","`");rt._applyWithArgs("exactly","`");xs=rt._many(proc{return rt._or((proc{return (proc{rt._not(proc{return rt._or((proc{return (proc{rt._applyWithArgs("exactly","\'");return rt._applyWithArgs("exactly","\'")}).call}))});return rt._apply("eChar")}).call}))});rt._applyWithArgs("exactly","\'");rt._applyWithArgs("exactly","\'");return ["App","seq",xs.join("").toProgramString()]}).call}))}).call}))
end

def sCharacters
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("exactly","\"");xs=rt._many(proc{return rt._or((proc{return (proc{rt._not(proc{return rt._applyWithArgs("exactly","\"")});return rt._apply("eChar")}).call}))});rt._applyWithArgs("exactly","\"");return ["App","token",xs.join("").toProgramString()]}).call}))}).call}))
end

def string
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{xs=rt._or((proc{return (proc{rt._or((proc{return (proc{return rt._applyWithArgs("exactly","#")}).call}),(proc{return (proc{return rt._applyWithArgs("exactly","`")}).call}));return rt._apply("tsName")}).call}),(proc{return (proc{return rt._apply("tsString")}).call}));return ["App","exactly",xs.toProgramString()]}).call}))}).call}))
end

def number
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{sign=rt._or((proc{return (proc{return rt._applyWithArgs("exactly","-")}).call}),(proc{return (proc{rt._apply("empty");return ""}).call}));ds=rt._many1(proc{return rt._apply("digit")});return ["App","exactly",(sign + ds.join(""))]}).call}))}).call}))
end

def keyword
xs = nil
return rt._or((proc{return (proc{(proc{return xs=rt._apply("anything")}).call;return rt._or((proc{return (proc{rt._applyWithArgs("token",xs);rt._not(proc{return rt._apply("letterOrDigit")});return xs}).call}))}).call}))
end

def hostExpr
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{r=rt._applyWithArgs("foreign",BSRubyParser,"expr");return rt._applyWithArgs("foreign",BSRubyTranslator,"trans",r)}).call}))}).call}))
end

def atomicHostExpr
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{r=rt._applyWithArgs("foreign",BSRubyParser,"semAction");return rt._applyWithArgs("foreign",BSRubyTranslator,"trans",r)}).call}))}).call}))
end

def args
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("token","(");xs=rt._applyWithArgs("listOf","hostExpr",",");rt._applyWithArgs("token",")");return xs}).call}),(proc{return (proc{rt._apply("empty");return []}).call}))}).call}))
end

def application
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rule=rt._apply("name");as=rt._apply("args");return ["App",rule].concat(as)}).call}))}).call}))
end

def semAction
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._or((proc{return (proc{return rt._applyWithArgs("token","!")}).call}),(proc{return (proc{return rt._applyWithArgs("token","->")}).call}));x=rt._apply("atomicHostExpr");return ["Act",x]}).call}))}).call}))
end

def semPred
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("token","?");x=rt._apply("atomicHostExpr");return ["Pred",x]}).call}))}).call}))
end

def expr
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{xs=rt._applyWithArgs("listOf","expr4","|");return ["Or"].concat(xs)}).call}))}).call}))
end

def expr4
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{xs=rt._many(proc{return rt._apply("expr3")});return ["And"].concat(xs)}).call}))}).call}))
end

def optIter
x = nil
return rt._or((proc{return (proc{(proc{return x=rt._apply("anything")}).call;return rt._or((proc{return (proc{rt._applyWithArgs("token","*");return ["Many",x]}).call}),(proc{return (proc{rt._applyWithArgs("token","+");return ["Many1",x]}).call}),(proc{return (proc{rt._apply("empty");return x}).call}))}).call}))
end

def expr3
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{x=rt._apply("expr2");x=rt._applyWithArgs("optIter",x);return rt._or((proc{return (proc{rt._applyWithArgs("exactly",":");n=rt._apply("name");return (proc{@locals << n; return ["Set",n,x]}).call}).call}),(proc{return (proc{rt._apply("empty");return x}).call}))}).call}),(proc{return (proc{rt._applyWithArgs("token",":");n=rt._apply("name");return (proc{@locals << n; return ["Set",n,["App","anything"]]}).call}).call}))}).call}))
end

def expr2
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("token","~");x=rt._apply("expr2");return ["Not",x]}).call}),(proc{return (proc{rt._applyWithArgs("token","&");x=rt._apply("expr1");return ["Lookahead",x]}).call}),(proc{return (proc{return rt._apply("expr1")}).call}))}).call}))
end

def expr1
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{return rt._apply("application")}).call}),(proc{return (proc{return rt._apply("semAction")}).call}),(proc{return (proc{return rt._apply("semPred")}).call}),(proc{return (proc{x=rt._or((proc{return (proc{return rt._applyWithArgs("keyword","undefined")}).call}),(proc{return (proc{return rt._applyWithArgs("keyword","nil")}).call}),(proc{return (proc{return rt._applyWithArgs("keyword","true")}).call}),(proc{return (proc{return rt._applyWithArgs("keyword","false")}).call}));return ["App","exactly",x]}).call}),(proc{return (proc{rt._apply("spaces");return rt._or((proc{return (proc{return rt._apply("characters")}).call}),(proc{return (proc{return rt._apply("sCharacters")}).call}),(proc{return (proc{return rt._apply("string")}).call}),(proc{return (proc{return rt._apply("number")}).call}))}).call}),(proc{return (proc{rt._applyWithArgs("token","[");x=rt._apply("expr");rt._applyWithArgs("token","]");return ["Form",x]}).call}),(proc{return (proc{rt._applyWithArgs("token","(");x=rt._apply("expr");rt._applyWithArgs("token",")");return x}).call}))}).call}))
end

def ruleName
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{return rt._apply("name")}).call}),(proc{return (proc{rt._apply("spaces");return rt._apply("tsString")}).call}))}).call}))
end

def rule
n = nil
x = nil
return rt._or((proc{return (proc{(proc{});
														return rt._or((proc{return (proc{rt._lookahead(
	proc{return rt._or((proc{return (proc{return n=rt._apply("ruleName")}).call}))});
	@locals = []
	x=rt._applyWithArgs("rulePart",n);xs=rt._many(proc{return rt._or((proc{return (proc{rt._applyWithArgs("token",",");return rt._applyWithArgs("rulePart",n)}).call}))});return ["Rule",n,@locals,["Or",x].concat(xs)]}).call}))}).call}))
end

def rulePart
n = nil
rn = nil
return rt._or((proc{return (proc{(proc{return rn=rt._apply("anything")}).call;return rt._or((proc{return (proc{n=rt._apply("ruleName");rt._pred((n == rn));b1=rt._apply("expr4");return rt._or((proc{return (proc{rt._applyWithArgs("token","=");b2=rt._apply("expr");return ["And",b1,b2]}).call}),(proc{return (proc{rt._apply("empty");return b1}).call}))}).call}))}).call}))
end

def grammar
return rt._or((proc{return (proc{(proc{});return rt._or((proc{return (proc{rt._applyWithArgs("keyword","ometa");n=rt._apply("name");sn=rt._or((proc{return (proc{rt._applyWithArgs("token","<:");return rt._apply("name")}).call}),(proc{return (proc{rt._apply("empty");return "OMeta"}).call}));rt._applyWithArgs("token","{");rs=rt._applyWithArgs("listOf","rule",",");rt._applyWithArgs("token","}");return ["Grammar",n,sn].concat(rs)}).call}))}).call}))
end
end

class RubyOMetaTranslator < OMeta
def trans
t = ans = nil
return (proc{_form(proc{return (proc{t=_apply("anything");return ans=_applyWithArgs("apply",t)}).call});return ans}).call
end

def App
args = rule = args = rule = nil
return _or((proc{return (proc{_applyWithArgs("exactly","super");args=_many1(proc{return _apply("anything")});return ['_superApplyWithArgs(', args.join(','), ')'].join('')}).call}),(proc{return (proc{rule=_apply("anything");args=_many1(proc{return _apply("anything")});return ['_applyWithArgs("', rule, '",',      args.join(','), ')'].join('')}).call}),(proc{return (proc{rule=_apply("anything");return ['_apply("', rule, '")']                                  .join('')}).call}))
end

def Act
expr = nil
return (proc{expr=_apply("anything");return expr}).call
end

def Pred
expr = nil
return (proc{expr=_apply("anything");return ['_pred(', expr, ')']                                     .join('')}).call
end

def Or
xs = nil
return (proc{xs=_many(proc{return _apply("transFn")});return ['_or(', xs.join(','), ')']                               .join('')}).call
end

def And
xs = y = nil
return _or((proc{return (proc{xs=_many(proc{return _applyWithArgs("notLast","trans")});y=_apply("trans");return (( xs.push('return ' + y); ['(proc{', xs.join(';'), '}).call'].join('') ))}).call}),(proc{return '(proc{})'}))
end

def Many
x = nil
return (proc{x=_apply("trans");return ['_many(proc{return ', x, '})']                     .join('')}).call
end

def Many1
x = nil
return (proc{x=_apply("trans");return ['_many1(proc{return ', x, '})']                    .join('')}).call
end

def Set
n = v = nil
return (proc{n=_apply("anything");v=_apply("trans");return [n, '=', v].join('')}).call
end

def Not
x = nil
return (proc{x=_apply("trans");return ['_not(proc{return ', x, '})']                      .join('')}).call
end

def Lookahead
x = nil
return (proc{x=_apply("trans");return ['_lookahead(proc{return ', x, '})']                .join('')}).call
end

def Form
x = nil
return (proc{x=_apply("trans");return ['_form(proc{return ', x, '})']                     .join('')}).call
end

def Rule
name = ls = body = nil
return (proc{name=_apply("anything");ls=_apply("locals");body=_apply("trans");return ["def ", name, "\n", ls, "\nreturn ", body, "\nend\n"]         .join('')}).call
end

def Grammar
name = sName = rules = nil
return (proc{name=_apply("anything");sName=_apply("anything");rules=_many(proc{return _apply("trans")});return ["Class.new(", sName, ") do\n@name = ", name.inspect, "\n", rules.join("\n"), 'end']      .join('')}).call
end

def locals
vs = nil
return _or((proc{return (proc{_form(proc{return vs=_many1(proc{return _apply("anything")})});return vs.map { |v| "#{v} = " }.join + 'nil'}).call}),(proc{return (proc{_form(proc{return (proc{})});return ''}).call}))
end

def transFn
x = nil
return (proc{x=_apply("trans");return ['(proc{return ', x, '})']                               .join('')}).call
end
end

