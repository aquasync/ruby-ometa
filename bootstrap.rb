require 'runtime'

class String
	def toProgramString
		inspect
	end
end

class BSRubyParser < OMeta
	def eChar
	c = nil
	return _or((proc{return (proc{_applyWithArgs("exactly","\\");c=_apply("char");return eval("\"\\" + c + "\"")}).call}),(proc{return _apply("char")}))
	end

	def tsString
	xs = nil
	return (proc{_applyWithArgs("exactly","'");xs=_many(proc{return (proc{_not(proc{return _applyWithArgs("exactly","'")});return _apply("eChar")}).call});_applyWithArgs("exactly","'");return xs.join('')}).call
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
def nameFirst

return _or((proc{return _applyWithArgs("exactly","_")}),(proc{return _applyWithArgs("exactly","$")}),(proc{return _apply("letter")}))
end

def nameRest

return _or((proc{return _apply("nameFirst")}),(proc{return _apply("digit")}))
end

def tsName
xs = nil
return (proc{xs=_applyWithArgs("firstAndRest","nameFirst","nameRest");return xs.join('')}).call
end

def name

return (proc{_apply("spaces");return _apply("tsName")}).call
end

def eChar
c = nil
return _or((proc{return (proc{_applyWithArgs("exactly","\\");c=_apply("char");return eval("\"\\" + c + "\"")}).call}),(proc{return _apply("char")}))
end

def tsString
xs = nil
return (proc{_applyWithArgs("exactly","'");xs=_many(proc{return (proc{_not(proc{return _applyWithArgs("exactly","'")});return _apply("eChar")}).call});_applyWithArgs("exactly","'");return xs.join('')}).call
end

def characters
xs = nil
return (proc{_applyWithArgs("exactly","`");_applyWithArgs("exactly","`");xs=_many(proc{return (proc{_not(proc{return (proc{_applyWithArgs("exactly","'");return _applyWithArgs("exactly","'")}).call});return _apply("eChar")}).call});_applyWithArgs("exactly","'");_applyWithArgs("exactly","'");return ['App', 'seq',     xs.join('').toProgramString()]}).call
end

def sCharacters
xs = nil
return (proc{_applyWithArgs("exactly","\"");xs=_many(proc{return (proc{_not(proc{return _applyWithArgs("exactly","\"")});return _apply("eChar")}).call});_applyWithArgs("exactly","\"");return ['App', 'token',   xs.join('').toProgramString()]}).call
end

def string
xs = nil
return (proc{xs=_or((proc{return (proc{_or((proc{return _applyWithArgs("exactly","#")}),(proc{return _applyWithArgs("exactly","`")}));return _apply("tsName")}).call}),(proc{return _apply("tsString")}));return ['App', 'exactly', xs.toProgramString()]}).call
end

def number
sign = ds = nil
return (proc{sign=_or((proc{return _applyWithArgs("exactly","-")}),(proc{return (proc{_apply("empty");return ''}).call}));ds=_many1(proc{return _apply("digit")});return ['App', 'exactly', sign + ds.join('')]}).call
end

def keyword
xs = nil
return (proc{xs=_apply("anything");_applyWithArgs("token",xs);_not(proc{return _apply("letterOrDigit")});return xs}).call
end

def hostExpr
r = nil
return (proc{r=_applyWithArgs("foreign",BSRubyParser,"expr");return _applyWithArgs("foreign",BSRubyTranslator,"trans",r)}).call
end

def atomicHostExpr
r = nil
return (proc{r=_applyWithArgs("foreign",BSRubyParser,"semAction");return _applyWithArgs("foreign",BSRubyTranslator,"trans",r)}).call
end

def args
xs = nil
return _or((proc{return (proc{_applyWithArgs("token","(");xs=_applyWithArgs("listOf","hostExpr",",");_applyWithArgs("token",")");return xs}).call}),(proc{return (proc{_apply("empty");return []}).call}))
end

def application
rule = as = nil
return (proc{rule=_apply("name");as=_apply("args");return ['App', rule].concat(as)}).call
end

def semAction
x = nil
return (proc{_or((proc{return _applyWithArgs("token","!")}),(proc{return _applyWithArgs("token","->")}));x=_apply("atomicHostExpr");return ['Act',  x]}).call
end

def semPred
x = nil
return (proc{_applyWithArgs("token","?");x=_apply("atomicHostExpr");return ['Pred', x]}).call
end

def expr
xs = nil
return (proc{xs=_applyWithArgs("listOf","expr4","|");return ['Or'].concat(xs)}).call
end

def expr4
xs = nil
return (proc{xs=_many(proc{return _apply("expr3")});return ['And'].concat(xs)}).call
end

def optIter
x = nil
return (proc{x=_apply("anything");return _or((proc{return (proc{_applyWithArgs("token","*");return ['Many',  x]}).call}),(proc{return (proc{_applyWithArgs("token","+");return ['Many1', x]}).call}),(proc{return (proc{_apply("empty");return x}).call}))}).call
end

def expr3
x = x = n = n = nil
return _or((proc{return (proc{x=_apply("expr2");x=_applyWithArgs("optIter",x);return _or((proc{return (proc{_applyWithArgs("exactly",":");n=_apply("name");return (@locals << n; ['Set', n, x])}).call}),(proc{return (proc{_apply("empty");return x}).call}))}).call}),(proc{return (proc{_applyWithArgs("token",":");n=_apply("name");return (@locals << n; ['Set', n, ['App', 'anything']])}).call}))
end

def expr2
x = x = nil
return _or((proc{return (proc{_applyWithArgs("token","~");x=_apply("expr2");return ['Not',       x]}).call}),(proc{return (proc{_applyWithArgs("token","&");x=_apply("expr1");return ['Lookahead', x]}).call}),(proc{return _apply("expr1")}))
end

def expr1
x = x = x = nil
return _or((proc{return _apply("application")}),(proc{return _apply("semAction")}),(proc{return _apply("semPred")}),(proc{return (proc{x=_or((proc{return _applyWithArgs("keyword","undefined")}),(proc{return _applyWithArgs("keyword","nil")}),(proc{return _applyWithArgs("keyword","true")}),(proc{return _applyWithArgs("keyword","false")}));return ['App', 'exactly', x]}).call}),(proc{return (proc{_apply("spaces");return _or((proc{return _apply("characters")}),(proc{return _apply("sCharacters")}),(proc{return _apply("string")}),(proc{return _apply("number")}))}).call}),(proc{return (proc{_applyWithArgs("token","[");x=_apply("expr");_applyWithArgs("token","]");return ['Form', x]}).call}),(proc{return (proc{_applyWithArgs("token","(");x=_apply("expr");_applyWithArgs("token",")");return x}).call}))
end

def ruleName

return _or((proc{return _apply("name")}),(proc{return (proc{_apply("spaces");return _apply("tsString")}).call}))
end

def rule
n = x = xs = nil
return (proc{_lookahead(proc{return n=_apply("ruleName")});@locals = [];x=_applyWithArgs("rulePart",n);xs=_many(proc{return (proc{_applyWithArgs("token",",");return _applyWithArgs("rulePart",n)}).call});return ['Rule', n, @locals, ['Or', x].concat(xs)]}).call
end

def rulePart
rn = n = b1 = b2 = nil
return (proc{rn=_apply("anything");n=_apply("ruleName");_pred(n == rn);b1=_apply("expr4");return _or((proc{return (proc{_applyWithArgs("token","=");b2=_apply("expr");return ['And', b1, b2]}).call}),(proc{return (proc{_apply("empty");return b1}).call}))}).call
end

def grammar
n = sn = rs = nil
return (proc{_applyWithArgs("keyword","ometa");n=_apply("name");sn=_or((proc{return (proc{_applyWithArgs("token","<:");return _apply("name")}).call}),(proc{return (proc{_apply("empty");return OMeta}).call}));_applyWithArgs("token","{");rs=_applyWithArgs("listOf","rule",",");_applyWithArgs("token","}");return ['Grammar', n, sn].concat(rs)}).call
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

