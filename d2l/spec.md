# LUIF Direct-to-Lua (D2L, d2l) calls

This is a write-up on defining LUIF BNF statements as first-class Lua objects along the lines of [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html#intro).

To quote Roberto:

> Following the Snobol tradition, LPeg defines patterns as first-class objects. That is, patterns are regular Lua values (represented by userdata). The library offers several functions to create and compose patterns. With the use of metamethods, several of these functions are provided as infix or prefix operators. On the one hand, the result is usually much more verbose than the typical encoding of patterns using the so called regular expressions (which typically are not regular expressions in the formal sense). On the other hand, first-class patterns allow much better documentation (as it is easy to comment the code, to break complex definitions in smaller parts, etc.) and are extensible, as we can define new functions to create and compose patterns.

## Functions

`luif.G{...}` takes a table of LUIF rules expressed as direct-to-Lua calls
and returns a table representing LUIF rules for KHIL. ([LPeg counterpart]
(http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html#grammar)).

`luif.S(string)`, `luif.L(string)`, and `luif.C(string)` prefix strings serving as LUIF symbols, literals and character classes, accordingly.

`luif.Q(string)` marks string as a quantifier for sequence rules.

`luif.hide(...)` and `luif.group(...)` take a list of prefixed D2L strings and provide LUIF hiding and grouping.

`'|'`, `'||'`, `'%%'`, and `'%'` literals are used
in the meaning defined by the LUIF grammar for `|`, `||`, `%%`, and `%`.
If an application needs such literals in its grammar,
it must prefix them with `luif.L`, e.g. `luif.L'|'`.

`khil.grammar_new_from_table(name, luif.G{...})` adds a grammar returned by `luif.G{...}` call under key `name` to KHIL table of grammars.

[Note: The below function is a suggestion, possibly too forward-looking]

`khil.grammar_new_from_string(name, source)` adds a grammar contained in `source` string under key `name` to KHIL table of grammars. `string` must contain a grammar table serialized so that it evaluates to a valid LUIF grammar representation by `loadstring(string [, chunkname])`. The intended use is binding Kollos from another language by writing direct-to functions specified above in such language.

The two functions above must infer lexical rules, like `Number = C'[0-9]'`
by checking that their RHSes contain only literals, charclasses and LHSes of other rules, which have only literals and charclasses on their RHSes. They need to build lexical and structural grammars and check them for compatibility via lexemes.

## LUIF Rules

LUIF rules are built as Lua tables, whose fields can be built using direct-to-Lua functions and literals specified above.

### Single RHS alternative

```lua
local grammar = luif.G{
  ...
  -- without adverbs
  lhs = { luif.S'symbol', luif.S'another_symbol', ... luif.L'literal' }
  -- with adverbs
  lhs = {
    luif.S'symbol', luif.S'another_symbol', ... luif.L'literal',
    { action = function(...) ... end }
  }
}
```

#### Sequence Rules

Sequence rules have single RHS alternative

```lua
local grammar = luif.G{
  ...
  seq = { S'item', Q'+', '%', S'separator' },
  seq = { S'item', Q'+', '%%', S'separator' },
  seq = { S'item', Q'+', '%', L',' }, -- literal as sequence separator
}
```

[todo: are we going to support charclasses as sequence separators? ]

### Multiple RHS alternatives

In the case of several RHS alternatives, the LUIF rule table becomes

```lua
local grammar = luif.G{
  ...
  lhs = {
    -- first alternative, tightest precedence
    { luif.S'symbol', luif.S'another_symbol', ... luif.L'literal' },
    -- without precedence, '|' is implied
    { luif.S'symbol', luif.S'another_symbol', ... luif.L'literal' },
    -- with looser precedence
    { '||', luif.S'symbol', luif.S'another_symbol', ... luif.L'literal' },
    -- with the same precedence
    { '|', luif.S'symbol', luif.S'another_symbol', ... luif.L'literal' },
  },
  ...
}
```

The first field of an RHS alternative other than the first can be `'|'` or `'||'`
that set precedence of such alternative according to LUIF grammar.
If the first field is not `'|'` or `'||'`, then `'|'` is implied.

### Adverbs

The below adverbs can be specified as a { name = value, ... } field
at the end of a LUIF rule table.

```
hidden:      true, false              -- alternative hidden from semantics
group:       true, false              -- gropued alternative
proper:      true, false              -- proper sequence separation
action:      function (...) block end -- todo: other descriptors
quantifier:  '+', '*'                 -- sequence quantifier
precedence:  '|', '||'
```

## Example 1: Calculator Grammar

### Calculator LUIF

```
Script ::= Expression+ % ','
Expression ::=
  Number
  | '(' Expression ')'
 || Expression '**' Expression, action = function (...) return arg[1] ^ arg[2] end
 || Expression '*' Expression, action = function (...) return arg[1] * arg[2] end
  | Expression '/' Expression, action = function (...) return arg[1] / arg[2] end
 || Expression '+' Expression, action = function (...) return arg[1] + arg[2] end
  | Expression '-' Expression, action = function (...) return arg[1] - arg[2] end
 Number ~ [0-9]+
```

### Calculator Direct-to-Lua

```lua
local calc = luif.G{
  Script = { S'Expression', Q'+', '%', L',' },
  Expression = {
    { S'Number' },
    { '|' , '(', S'Expression', ')' },
    { '||', S'Expression', L'**', S'Expression', { action = pow } },
    { '||', S'Expression', L'*', S'Expression', { action = mul } },
    { '|' , S'Expression', L'/', S'Expression', { action = div } },
    { '||', S'Expression', L'+', S'Expression', { action = add } },
    { '|' , S'Expression', L'-', S'Expression', { action = sub } },
  },
  Number = C'[0-9]'
}
```

Note: See `d2l.lua` for the complete example.

## Example 1: JSON Grammar

[todo: use the full json grammar from the example in `manual.md` ]

### JSON LUIF

```
json     ::= object
           | array
object   ::= [ '{' '}' ]
           | [ '{' ] members [ '}' ]
members  ::= pair+ % comma
pair     ::= string [ ':' ] value
value    ::= string
           | object
           | number
           | array
           | true
           | false
           | null
array    ::= [ '[' ']' ]
           | [ '[' ] elements [ ']' ]
elements ::= value+ % comma
string   ::= [todo]

comma    ~ ','

true     ~ 'true' # [todo: true and false are Lua keywords: KHIL needs to handle this]
false    ~ 'false'
null     ~ 'null'
```

### JSON Direct-to-Lua

```lua
local json = luif.G{

  json = {
    { S'object' },
    { S'array' }
  },

  object = {
    { luif.hide( L'{', L'}' ) },
    { luif.hide( L'{' ), S'members', luif.hide( L'}' ) }
  },

  members = { S'pair', Q'+', '%', S'comma' },

  pair = {
    { S'string', luif.hide( L':' ), S'value' }
  },

  value = {
    { S'string' },
    { S'object' },
    { S'number' },
    { S'array' },
    { S'S_true' },
    { S'S_false' },
    { S'null' },
  },

  array = {
    { luif.hide( L'[', L']' ) },
    { luif.hide( L'[' ), S'elements', luif.hide( L']' ) },
  },

  elements = { S'value', Q'+', '%', S'comma' },

  string = { '[todo]' },

  comma = L',',

  S_true  = L'true', -- true and false are Lua keywords
  S_false = L'false',
  null  = L'null',

}
```

## External Grammar (LUIF Rules) Representation for KHIL

[todo: this the below sketch ]

D2L calls must build
a Lua table of LUIF rules (can be based on SLIF MetaAST)
to be passed to KHIL
for conversion to KIR.

```lua
luif = {
  name = {
    -- structural
    g1 = {
      {
        lhs = 'Expression'
        rhs = {}
        adverbs = {
          action = function(...) end
          precedence = '|' -- or should it be numeric?
        },
      },
      {
        lhs = 'Script',
        rhs = { 'Expression',  },
        adverbs = {
          action = function(...) end
          quantifier =                  -- '+' or '*'
          proper = true                 -- true or false
        },
      },
    },
    -- lexical
    l0 = {
      {
        lhs = 'Lex-1',
        rhs = { ',' }
      },
      {
        lhs = 'Number'
        rhs = { [] }
      },
    }
  }
}
```

