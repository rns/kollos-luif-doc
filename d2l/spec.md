﻿# LUIF Direct-to-Lua (D2L) Calls and Format

Direct-to-Lua (D2L) calls allow working with LUIF statements as first-class Lua objects along the lines of [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html#intro).

To quote Roberto:

> Following the Snobol tradition, LPeg defines patterns as first-class objects. That is, patterns are regular Lua values (represented by userdata). The library offers several functions to create and compose patterns. With the use of metamethods, several of these functions are provided as infix or prefix operators. On the one hand, the result is usually much more verbose than the typical encoding of patterns using the so called regular expressions (which typically are not regular expressions in the formal sense). On the other hand, first-class patterns allow much better documentation (as it is easy to comment the code, to break complex definitions in smaller parts, etc.) and are extensible, as we can define new functions to create and compose patterns.

In the LUIF, Direct-to-Lua (D2L) calls are used to transform LUIF statements into Kollos Intermediate Representation (KIR) table, provide programmatic grammar construction, and, with the use of special table constructors, serve as a representation format for LUIF grammars.

## Functions

Bare literals except for special literals (see below) define symbols.

`luif.G{...}` takes a table of LUIF rules expressed as direct-to-Lua calls
and returns a table representing LUIF rules for KHIL. ([LPeg counterpart]
(http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html#grammar)).

`luif.S(S_item, quantifier, operator, S_separator)` defines
a [counted (sequence) rule](../manual.md#sequences).

`luif.L(string)`, and `luif.C(string)` prefix strings serving as LUIF literals and character classes, accordingly.

`luif.hide(...)` and `luif.group(...)` take a list of prefixed D2L strings and provide LUIF hiding and grouping.

Special `'|'`, `'||'`, `'%%'`, `'~'` and `'%'` literals are used
in the meaning defined by the LUIF grammar for `|`, `||`, `%%`, `~` and `%`.
If an application needs such literals in its grammar,
it must prefix them with `luif.L`, e.g. `luif.L'|'`.

`luif.grammar_new(key, table)`
produces Kollos Intermediate Representation (KIR)
of the grammar contained in `table` and
adds it under `key` to KIR’s table of grammars.
The `table` must be produced by a call to `luif.G()`.

`luif.grammar_loadstring(key, string)`
produces KIR of the grammar contained in `string` and
adds it under `key` to KIR’s table of grammars.
`string` must contain a grammar table serialized so
that it evaluates to a valid LUIF grammar representation
by `loadstring(string [, chunkname])`.
The intended use is binding Kollos
from another language
by writing 'direct-to' functions
specified above in such language.

[todo: write proof-of-concept 'direct-to' code in Perl and other languages]

## LUIF Rules

LUIF rules are written as Lua tables, whose fields can be set using D2L functions and literals specified above.

### Single RHS alternative

```lua
local grammar = luif.G{
  ...
  -- without adverbs
  lhs = { 'symbol', 'another_symbol', ... luif.L'literal' }
  -- with adverbs
  lhs = {
    'symbol', 'another_symbol', ... luif.L'literal',
    { action = function(...) ... end }
  }
}
```

#### Sequence Rules

Sequence rules have single RHS alternative, their syntax is

```lua
local S, L = luif.S, luif.L
local grammar = luif.G{
  ...
  seq = S{ 'item', '+', '%', 'separator' },
  seq = S{ 'item', '+', '%%', 'separator' },
  seq = S{ 'item', '+', '%', L',' }, -- literal as sequence separator
  seq = S{ 'item', '+', '%', C'[;,]' }, -- character class as sequence separator
}
```

Note:

[todo: define support for SLIF extensions per https://github.com/rns/kollos-luif-doc/issues/17]

### Multiple RHS alternatives

In the case of several RHS alternatives, the LUIF rule syntax is

```lua
local S, L = luif.S, luif.L
local grammar = luif.G{
  ...
  lhs = {
    -- first alternative, tightest precedence
    { 'symbol', 'another_symbol', ... L'literal' },
    -- without precedence, '|' is implied
    { 'symbol', 'another_symbol', ... L'literal' },
    -- with looser precedence
    { '||', 'symbol', 'another_symbol', ... L'literal' },
    -- with the same precedence
    { '|', 'symbol', 'another_symbol', ... L'literal' },
  },
  ...
}
```

The first field of an RHS alternative other than the first can be `'|'` or `'||'`
that sets the same or looser precedence for it.
If the first field is not `'|'` or `'||'`, then `'|'` is implied.

### Lexical and Structural Rules

By default, LUIF rules are structural;
lexical rules can be defined by setting the first field in the rule table to `'~'`:

```
  cardinal = { '~', C'[0-9]+' },
  double_quoted_string = { '~', L'"', C'[^"]+', L"'" },
```

### Adverbs

The below adverbs can be specified as a `{ name = value, ... }` field
at the end of a LUIF rule table.

```
hidden:      true, false              -- alternative is hidden from semantics
group:       true, false              -- alternative is grouped
proper:      true, false              -- proper sequence separation
action:      function (...) block end -- [todo: other descriptors]
quantifier:  '+', '*'                 -- sequence quantifier
precedence:  '|', '||'
```

## Examples

### Example 1: Calculator Grammar

#### Calculator Grammar in LUIF

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

#### Calculator Grammar in D2L

```lua
local calc = luif.G{
  Script = S{ 'Expression', '+', '%', L',' },
  Expression = {
    { 'Number' },
    { '|' , '(', 'Expression', ')' },
    { '||', 'Expression', L'**', 'Expression', { action = pow } },
    { '||', 'Expression', L'*', 'Expression', { action = mul } },
    { '|' , 'Expression', L'/', 'Expression', { action = div } },
    { '||', 'Expression', L'+', 'Expression', { action = add } },
    { '|' , 'Expression', L'-', 'Expression', { action = sub } },
  },
  Number = C'[0-9]'
}
```

### Example 2: JSON Grammar

#### JSON Grammar in LUIF

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

#### JSON Grammar in D2L

```lua
local json = luif.G{

  json = {
    { 'object' },
    { 'array' }
  },

  object = {
    { luif.hide( L'{', L'}' ) },
    { luif.hide( L'{' ), 'member', luif.hide( L'}' ) }
  },

  members = S{ 'pair', '+', '%', 'comma' },

  pair = {
    { 'string', luif.hide( L':' ), 'value' }
  },

  value = {
    { 'string' },
    { 'object' },
    { 'number' },
    { 'array' },
    { 'S_true' },
    { 'S_false' },
    { 'null' },
  },

  array = {
    { luif.hide( L'[', L']' ) },
    { luif.hide( L'[' ), 'element', luif.hide( L']' ) },
  },

  elements = S{ 'value', '+', '%', 'comma' },

  string = { '[todo]' },

  comma = L',',

  S_true  = L'true', -- true and false are Lua keywords
  S_false = L'false',
  null  = L'null',

}
```
