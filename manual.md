# The LUIF

Warning: this is a working draft.

## Overview

This document desribes the LUIF (LUa InterFace),
the interface language of
the [Kollos project](https://github.com/jeffreykegler/kollos/).

The LUIF is Lua, extended with [BNF](http://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form) statements.

[todo: consider rearranging the sections after more content is added
to follow the Lua manual bottom-up pattern of introducing individual constructs with grammar snippets first and presenting the full syntax in the final section. ]

## BNF statement

There is only one BNF statement, combining precedence, sequences, and alternation.

LUIF extends the Lua syntax by adding `bnf` alternative to `stat` rule of the [Lua grammar](http://www.lua.org/manual/5.1/manual.html#8) and introducing the new rules. The general syntax for a BNF statement is as follows (`stat`, `block`, `var`, `field`, `Name`, and `String` symbols are as defined by the Lua grammar):

Note: this describes LUIF structural and lexical grammars 'used in the default way' as defined in [Grammars](#grammars) section below. The first rule will act as the start rule.

[todo: make sure it conforms to other sections]

```
stat ::= bnf

bnf ::= lhs produce_op rhs  -- to make references LHS/RHS easier to understand

lhs ::= symbol_name

produce_op ::= '::=' |
               '~'

rhs ::= precedenced_alternative { '||' precedenced_alternative }

precedenced_alternative ::= alternative { '|' alternative }

alternative ::= rhslist { ',' adverb }

adverb ::= field |
           action

action ::= 'action' '=' actionexp

actionexp ::= 'function' '(...)' block end
              -- borrow array descriptors from SLIF?

rhslist ::= { rh_atom }       -- can be empty, like Lua chunk

rh_atom ::= var |             -- Lua variable, for programmatic grammar construction
            separated_sequence |
            symbol_name |
            literal |
            charclass |
            '(' alternative ')' |
            '[' alternative ']'

separated_sequence ::= sequence  |
                       sequence '%'  separator | -- proper separation
                       sequence '%%' separator

separator ::= symbol_name

sequence ::= symbol_name '+' |
             symbol_name '*' |
             symbol_name '?' |
             symbol_name '*' Number '..' Number |
             symbol_name '*' Number '..' '*'

symbol_name :: Name

literal ::= String

charclass ::= String -- must contain a Lua pattern as per http://www.lua.org/manual/5.1/manual.html#5.4.1

```

[todo: implementation detail: Lua patterns can be much slower than regexes, so we can
use lua patterns as they are or
translate them to regexes for speed
or make this an option ]

[todo: implementation suggestion: Lua patterns include
[`%bxy`](http://www.lua.org/pil/20.2.html),
which matches balanced delimiters, LUIF can extend it
to match nested balanced delimiters
which seems to be a fairly common use case.
]

## Sequences

Sequences are expressions on the RHS of a BNF rule alternative
which imply the repetition of a symbol,
or a parenthesized series of symbols. The general syntax for sequences is

[todo: add sequence snippet from the LUIF grammar ]
```
```

The item to be repeated (the repetend)
can be either a single symbol,
or a sequence of symbols grouped by
parentheses or square brackets,
as described above.
A repetiton consists of

+ A repetend, followed by
+ An optional puncuation specifier.

A repetition specifier is one of

```
    ** N..M     -- repeat between N and M times
    ** N..*     -- repeat more than N times
    ?           -- equivalent to ** 0..1
    *           -- equivalent to ** 0..*
    +           -- equivalent to ** 1..*
```

A punctuation specifier is one of
```
    % <sep>     -- use <sep> as a separator
    %% <sep>     -- use <sep> as a terminator
```
When a terminator specifier is in use,
the final terminator is optional.

Here are some examples:

```
    A+                 -- one or more <A> symbols
    A*                 -- zero or more <A> symbols
    A ** 42            -- exactly 42 <A> symbols
    <A> ** 3..*        -- 3 or more <A> symbols
    <A> ** 3..42       -- between 3 and 42 <A> symbols
    (<A> <B>) ** 3..42 -- between 3 and 42 repetitions of <A> and <B>
    [<A> <B>] ** 3..42 -- between 3 and 42 repetitions of <A> and <B>,
                       --   hidden from the semantics
    <a>* % ','         -- 0 or more comma-separated <a> symbols
    <a>+ % ','         -- 1 or more comma-separated <a> symbols
    <a>? % ','         -- 0 or 1 <a> symbols; note that ',' is never used
    <a> ** 2..* % ','  -- 2 or more comma-separated <a> symbols
    <A>+ % ','         -- one or more comma-separated <A> symbols
    <A>* % ','         -- zero or more comma-separated <A> symbols
    (A B)* % ','       -- A and B, repeated zero or more times, and comma-separated
    <A>+ %% ','        -- one or more comma-terminated <A> symbols

```

The repetend cannot be nullable.
If a separator is specified, it cannot be nullable.
If a terminator is specified, it cannot be nullable.
If you try to work out what repetition of a nullable item actually means,
I think the reason for these restrictions will be clear --
such a repetition is very ambiguous.
An application which really wants to specify rules involving nullable repetition,
can specify them directly in BNF,
and these will make the programmer's intent clear.

### Grouping and hidden symbols

To group a series of RHS symbols use parentheses:

```
   ( A B C )
```

You can also use square brackets,
in which case the symbols will be hidden
from the semantics:

```
   [ A B C ]
```

Parentheses and square brackets can be nested.
If square brackets are used at any nesting level
containing a symbol, that symbol is hidden.
In other words,
there is no way to "unhide" a symbol that is inside
square brackets.

### Symbol names

A LUIF symbol name is any valid Lua name.
Eventually names with non-initial hyphens will be allowed and an angle bracket notation for LUIF symbol names,
similar to that of
the [SLIF](https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod#Symbol-names),
will allow whitespace
in names.

### Literals

LUIF literals are Lua literal strings as defined in [Lexical Conventions](http://www.lua.org/manual/5.1/manual.html#2.1) section of the Lua 5.1 Reference Manual.

### Character classes

### Comments

LUIF comments are Lua comments as defined at the end of [Lexical Conventions](http://www.lua.org/manual/5.1/manual.html#2.1) section in the Lua 5.1 Reference Manual.

### Adverbs

#### action

## Locale support

Full support is only assured for the "C" locale -- support for other locales may be limited, inconsistent, or removed in the future.

Lua's `os.setlocale()`, when used in the LUIF context for anything but the "C" locale, may fail, silently or otherwise.

[todo: update the tentative language above as Kollos project progresses]

## Post-processing

The output of the KHIL will be a table, with one key for each grammar name.  Keys *must* be strings.  The value of each grammar key will be a table, with entries for external and internal symbols and rules.  Details of the format will be specified later.

This table will be interpreted by the lower layer (KLOL).  Initially post-processing will take a very restricted form in the LUIF grammars.   There are two kinds of Libmarpa grammars: structural and lexical grammar.  A grammar is lexical if one or more of its rules have the special `lexeme` action.  The post-processing will expect a lexical grammar named `l0` and a structural grammar named `g1`, and will check (in the same way that Marpa::R2 currently does) to ensure they are compatible.

## Grammars <a id="grammars"></a>

BNF statements are grouped into one or more grammars.  The grammar is indicated by the produce-operator of the BNF. Its general form is `:grammar:=`, where `grammar` is the name of a grammar.  `grammar` must not contain colons.  Initially, the post-processing will not support anything but `l0` and `g1` used in the default way, like this:

```lua
-- structural grammar
a ::= b c       -- the first rule is the start rule
                -- using the LHS (b c) of a lexical rule
                -- on the RHS of a structural rule makes a lexeme
a ::= w
aa ::= a a

-- lexical grammar
w ~ x y z
b ~ 'b' x
c ~ 'c' y

x ~ 'x'
y ~ 'y'
z ~ [xyz]

```

If the produce-operator is `::=`, then the grammar is `g1`.  The tilde `~` can be a produce-operator, in which case it is equivalent to `:l0:=`.

A structural grammar will often contain lexical elements, such as strings and character classes, and these will go into its linked lexical grammar.  The start rule specifies its lexical grammar with an adverb (what?).  In a lexical grammar the lexemes are indicated with the `lexeme` adverb -- if a rule has a lexeme adverb, its LHS is a lexeme.

If a grammar specified lexemes, it is a lexical grammar.  If a grammar specified a linked lexical grammar, it is a structural grammar.  `l0` must always be a lexical grammar.  `g1` must always be a structural grammar and is linked by default to `l0`.  It is a fatal error if a grammar has no indication whether it is structural or lexical, but this indication may be a default.  Enforcement of these restrictions is done by the lower layer (KLOL).

## Example grammars

### Calculator

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

### JSON

```

-- structural

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
string   ::= lstring

-- lexical

comma          ~ ','
-- [todo: true and false are Lua keywords: KHIL needs to handle this]
S_true         ~ 'true'
S_false        ~ 'false'
null           ~ 'null'
number         ~ int
               | int frac
               | int exp
               | int frac exp
int            ~ digits
               | '-' digits
digits         ~ [\d]+
frac           ~ '.' digits
exp            ~ e digits
e              ~ 'e'
               | 'e+'
               | 'e-'
               | 'E'
               | 'E+'
               | 'E-'
lstring        ~ quote in_string quote
quote          ~ ["]
in_string      ~ in_string_char*
in_string_char ~ [^"] | '\"'

whitespace     ~ [\s]+

-- [todo: specify equivalent in LUIF ]
:discard       ~ whitespace

```
