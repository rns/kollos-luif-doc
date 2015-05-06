# The LUIF

This document (which is currently a work-in-progress for further discussion) describes
the **LUIF** (**LU**a **I**nter**F**ace),
the interface language of
the [Kollos project](https://github.com/jeffreykegler/kollos/#about-kollos).

The LUIF is [Lua](http://www.lua.org/), extended with
[BNF](http://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form) statements
[as specified below](#bnf_statement).

## Table of Contents

[BNF Statement](#bnf_statement)<br/>
- [Structural and Lexical Grammars](#structural_and_lexical_grammars)<br/>
- [Grammars](#grammars)<br/>
- [Precedenced Rules](#precedenced_rules)<br/>
- [Sequences](#sequences)<br/>
- [Grouping and Hiding Symbols](#grouping_and_hiding_symbols)<br/>
- [Symbol Names](#symbol_names)<br/>
- [Literals](#literals)<br/>
- [Character Classes](#character_classes)<br/>
- [Comments](#comments)<br/>
- [Adverbs](#adverbs)<br/>
  - [`action`](#action)<br/>
  - [`completed`](#completed)<br/>
  - [`predicted`](#predicted)<br/>
  - [`assoc`](#assoc)

[Semantics](#semantics)<br/>
- [Defining Semantics with `action` adverb](#defining_semantics_with_action_adverb)<br/>
- [Context Accessors](#context_accessors)<br/>

[Events](#events)<br/>
[Post-Processing](#post_processing)<br/>
[Programmatic Grammar Construction](#programmatic_grammar_construction)<br/>
[Locale Support](#locale_support)<br/>
[The Complete Syntax of BNF Statement](#complete_syntax_of_bnf_statement)<br/>
[Example Grammars](#example_grammars)<br/>
- [Calculator](#calculator)<br/>
- [JSON](#json)<br/>

<a id="bnf_statement"></a>
## BNF Statement

LUIF extends the Lua syntax by adding `bnf` alternative to `stat` rule of the [Lua grammar](http://www.lua.org/manual/5.1/manual.html#8) and introducing the new rules for BNF statements. There is only one BNF statement, combining [precedence](#precedenced_rules),
[sequences](#sequences), and alternation as specified below.

A BNF statement specifies a rule, which consists of, in order:

- A left hand side (LHS), which will be a [symbol](#symbol_names).

- A produce-operator (`::=` or `~`).

- A right-hand side (RHS), which contains one or more RHS alternatives. A RHS alternative is a series of RHS primaries, where a RHS primary may be
a [symbol name](#symbol_names), a [character class](#character_classes), a [literal](#literals), a [sequence](#sequences) or another, [grouped or hidden](#grouping_and_hiding_symbols), RHS alternative.

<a id="structural_and_lexical_grammars"></a>
### Structural and Lexical Grammars

A grammar can be either structural or lexical.
A grammar is lexical if one of its rules contains the `lexeme` adverb.
A grammar is structural if it has a start rule.

By default, the LUIF start with two grammar in its grammar set:
`g1` and `l0`.
By default, `g1` is a structural grammar.
By default, `l0` is a lexical grammar,
and is the lexer for `g1`.
A structural grammar may specify its lexer
by using the `lexer` adverb in its start rule.

A grammar is always structural or lexical, but never both.
It is a fatal error if, according to the stipulations above,
a grammar would be both lexical and structural.
If applying the stipulations above does not determine
whether a grammar is lexical or structural,
then it defaults to structural.

A rule is structural if it belongs to a structural grammar.
A rule is lexical if it belongs to a lexical grammar.
Structural or lexical rules are declared by using produce-operators.

In a lexical grammar, a lexeme is a top-level symbol,
and must be specified with the `lexeme` adverb.
In a lexical grammar, a lexeme can never appear on a RHS.

In a structural grammar, a lexeme is a symbol which never appears
on the LHS of a rule.

Structural rules may imply lexical rules in the structural grammar's
associated lexer.
Charclasses and strings in structural rules, for example,
create lexemes in the associated lexical grammar.
It is a fatal error if a structural rule implies a lexical rule,
but the structural grammar has no
associated lexical grammar.

A _lexeme_ is a sequence of characters in the input matched by a rule in a lexical grammar.
Marpa's usage of the term "lexeme" is special to it.

For all pairings of structural grammars and their lexers,
both grammars in the pair must have a consistent idea of
which symbols are lexemes.
Full enforcement of this
and the other stipulations
of this section does not occur until
the lower layer (KLOL) processes the KIR.

<a id="grammars"></a>
## Grammars

[todo: rewrite according to the above and the discussion about grammar start statement at https://github.com/rns/kollos-luif-doc/issues/10]

BNF statements are grouped into one or more grammars.
The grammar is indicated by the produce-operator of the BNF. The general form
of the produce operator is
```
    :grammar:=
```
where `grammar` is the name of a grammar.  `grammar` must be a string
of the from acceptable as a Lua variable name.
Initially, the [post-processing](#post_processing) will not support anything but `l0` and `g1` used in the default way, like this:

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

<a id="precedenced_rules"></a>
### Precedenced Rules

A precedenced rule contains a series of one or more RHS alternatives, separated by either the alternation operator (`|`) or the loosen operators (`||`). In a typical grammar, most rules are precedenced rules, but they are often trivially precedenced, consisting of one or several RHS alternatives with equal precedence. For brevity, RHS alternatives are often called alternatives.

An alternative may be followed by a list of [adverbs](#adverbs).

The RHS alternatives in a precedenced right hand side proceed from tightest (highest) priority to loosest. The double "or" symbol (`||`) is the "loosen" operator -- the alternatives after it have a looser (lower) priority than the alternatives before it. The single "or" symbol (`|`) is the ordinary "alternative" operator -- alternatives on each side of it have the same priority. Associativity is specified using the [`assoc`](#assoc) adverb, as described below.

For a usage example of precedenced rules, see the [Calculator](#calculator) grammar below.

<a id="sequences"></a>
### Sequences

Sequences are expressions on the RHS of a BNF rule alternative
which imply the repetition of a symbol,
or a parenthesized series of symbols.

The item to be repeated (the repetend)
can be either a single symbol,
or a sequence of symbols grouped by
parentheses or square brackets,
as described above.
A repetition consists of

+ A repetend, followed by
+ An optional punctuation specifier.

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
    % <sep>     -- use <sep> as a proper separator
    %% <sep>    -- use <sep> as a liberal separator
    %- <sep>    -- proper separation, same as %
    %$ <sep>    -- use <sep> as a terminator
```
When proper separation is in use,
the separators must actually separate items.
A separator after the last item is not allowed.

When the separator is used as a terminator,
it must come after every item.
In particular, there *must* be a separator
after the last item.

A "liberal" separator may be used either
as a proper separator or a terminator.
That is, the separator after the last item
is optional.

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
    <a>* % ','         -- 0 or more properly comma-separated <a> symbols
    <a>+ % ','         -- 1 or more properly comma-separated <a> symbols
    <a>? % ','         -- 0 or 1 <a> symbols; note that ',' is never used
    <a> ** 2..* % ','  -- 2 or more properly comma-separated <a> symbols
    <A>+ % ','         -- one or more properly comma-separated <A> symbols
    <A>* % ','         -- zero or more properly comma-separated <A> symbols
    (A B)* % ','       -- A and B, repeated zero or more times, and properly comma-separated
    <A>+ %% ','        -- one or more comma-separated or comma-terminated <A> symbols

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

<a id="grouping_and_hiding_symbols"></a>
### Grouping and Hiding Symbols

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

A grouped or hidden series of RHS symbols can be followed by
a quantifier (`?`, `*` or `+`)
to define zero or one, zero or more, or one or more repetitions of such series.

<a id="symbol_names"></a>
### Symbol names

A LUIF symbol name is any valid Lua name.
Eventually names with non-initial hyphens will be allowed and an angle bracket notation for LUIF symbol names,
similar to that of
the [SLIF](https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod#Symbol-names),
will allow whitespace
in names.

<a id="literals"></a>
### Literals

LUIF literals are Lua _literal strings_ as defined in [Lexical Conventions](http://www.lua.org/manual/5.1/manual.html#2.1) section of the Lua 5.1 Reference Manual except that LUIF literals cannot be enclosed in long brackets.

<a id="character_classes"></a>
### Character classes

A character class is a string, which must contain
a valid [Lua character class](http://www.lua.org/manual/5.1/manual.html#5.4.1) as defined in the Lua reference manual.
Strings can be defined with character classes using sequence rules.

<a id="comments"></a>
### Comments

LUIF comments are Lua comments as defined at the end of [Lexical Conventions](http://www.lua.org/manual/5.1/manual.html#2.1) section in the Lua 5.1 Reference Manual.

<a id="adverbs"></a>
### Adverbs

A LUIF rule can be modified by one or more adverbs.
Adverbs are `name = value` pairs separated with commas.
A comma is also used to separate an adverb from the RHS alternative it modifies.

<a id="action"></a>
#### `action`

The `action` adverb defines the semantics of the RHS alternative it modifies.
Its value is specified in [Semantics](#semantics) section below.

The `action` adverb can also have a special `lexeme` value [descrived above](#structural_and_lexical_grammars).

<a id="completed"></a>
#### `completed`

The `completed` adverb defines
the Lua function to be called when the RHS alternative is completed during the parse.
Its value is the same as that of the `action` adverb.

For more details on parse events, see [Events](#events) section.

<a id="predicted"></a>
#### `predicted`

The `predicted` adverb defines
the Lua function to be called when the RHS alternative is predicted during the parse.
Its value is the same as that of the `action` adverb.

For more details on parse events, see [Events](#events) section.

<a id="assoc"></a>
#### `assoc`

The `assoc` adverb defines associativity of a [precedenced rule](#precedenced_rules).
Its value can be `left`, `right`, or `group`.
The function of this adverb is as defined in the [SLIF](https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod#assoc).

For a usage example, see the [Calculator](#calculator) grammar below.

<a id="semantics"></a>
## Semantics

The semantics of a BNF statement in the LUIF can be defined
by modifying its RHS alternatives
with [`action`](#defining_semantics_with_action_adverb) adverb.

<a id="defining_semantics_with_action_adverb"></a>
### Defining Semantics with `action` adverb

The value of an `action` adverb can be a body of a Lua function (`funcbody`) as defined in [Function Definitions](http://www.lua.org/manual/5.1/manual.html#2.5.9) section of the Lua 5.1 Reference Manual or the name of such function, which must be a bare name (not a namespaced or a method function's name).

The action functions will be called in the context where their respective BNF statements are defined. Their return values will become the values of the LHS symbols corresponding to the RHS alternatives modified by the `action` adverb.

The match context information, such as
matched rule data, input string locations and literals
will be provided by [context accessors](#context_accessors) in `luif.context` namespace.

If the semantics of a BNF statement is defined in a separate Lua file, LUIF functionality must be imported with Lua's [`require`] (http://www.lua.org/manual/5.1/manual.html#pdf-require) function.

The syntax for a semantic action function is

```lua
action = function (params) body end
```

It will be called as `f (params)`
with `params` set to
the values defined by the semantics of the matched RHS alternative's symbols.

[parameter list is under discussion at https://github.com/rns/kollos-luif-doc/issues/26]

<a id="context_accessors"></a>
#### Context Accessors

Context accessors live in the `luif.context` namespace.
They can be called from semantic actions to get matched rule and location data.
To import them into a separate file, use Lua's [`require`](http://www.lua.org/manual/5.1/manual.html#pdf-require) function, i.e.

```lua
require 'luif.context'
```

The context accessors are:

##### `lhs_id = luif.context.lhs()`

returns the integer ID of the symbol which is on the LHS of the BNF rule
whose semantic action or completed/predicted event handler is being called during the parse.

##### `rule_id = luif.context.rule()`

returns the integer ID of the BNF rule
whose semantic action or completed/predicted event handler is being called during the parse.

##### `alt_no = luif.context.alternative()`

returns the number of the BNF rule's RHS alternative
whose semantic action or completed/predicted event handler is being called during the parse.

##### `prec = luif.context.precedence()`

returns numeric precedence of
the alternative, whose semantic action or completed/predicted event handler is being called during the parse, relative to other alternatives or nil if no precedence is defined for the alternative.

##### `pos, len = luif.context.span()`

returns position and length of the input section corresponding to
the BNF rule whose semantic action or completed/predicted event handler is being called during the parse.

##### `string = luif.context.literal()`

returns the section of the input corresponding to
the BNF rule whose semantic action or completed/predicted event handler is being called during the parse.
It is defined by
the input span returned by the `luif.context.span()` function above.

##### `pos = luif.context.pos()`

returns the position in the input, which starts the span corresponding to
the BNF rule whose semantic action or completed/predicted event handler is being called during the parse.

##### `len = luif.context.length()`

returns the length of the input span corresponding to
the BNF rule whose semantic action or completed/predicted event handler is being called during the parse.

<a id="events"></a>
## Events

Parse events are defined using [`completed`](#completed) and [`predicted`](#predicted) adverbs.

[todo: provide getting started info/tutorial on parse events].

[todo: example/prototyping based on https://gist.github.com/rns/ba250ed6a5ed1c82ce7b]

<a id="post_processing"></a>
## Post-processing

LUIF grammars are transformed into KIR (Kollos Intermediate Runtime) tables using Direct-to-Lua (D2L) calls and format specified in a [separate document](d2l/spec.md).

[todo: rewrite to the end of the section]

The output will be a table, with one key for each grammar name.  Keys *must* be strings.  The value of each grammar key will be a table, with entries for external and internal symbols and rules.  Details of the format will be specified later.

The KIR table will be interpreted by the lower layer (KLOL).  Initially post-processing will take a very restricted form in the LUIF structural and lexical grammars.

The post-processing will expect a lexical grammar named `l0` and a structural grammar named `g1`, and will check (in the same way that Marpa::R2 currently does) to ensure they are compatible.

<a id="programmatic_grammar_construction"></a>
## Programmatic Grammar Construction (PGC)

Direct-to-Lua (D2L) calls can be used to build LUIF grammars programmatically.
The details are specified in a [separate document](d2l/spec.md).

At the moment, LUIF statements cannot be affected by Lua statements directly,
but this can change in future.

<a id="locale_support"></a>
## Locale support

Full support is only assured for the "C" locale -- support for other locales may be limited, inconsistent, or removed in the future.

Lua's `os.setlocale()`, when used in the LUIF context for anything but the "C" locale, may fail, silently or otherwise.

[todo: update the tentative language above as Kollos project progresses]

<a id="complete_syntax_of_bnf_statement"></a>
## The Complete Syntax of BNF Statement

The general syntax for a BNF statement is as follows (`stat`, `block`, `funcbody`, `Name`, and `String` symbols are as defined by the Lua grammar):

Note: this describes LUIF structural and lexical grammars 'used in the default way' as defined in [Grammars](#grammars) section above. The first rule will act as the start rule.

```
stat ::= bnf

bnf ::= lhs produce_op rhs  -- to make references to LHS/RHS easier to understand

lhs ::= symbol_name

produce_op ::= '::=' |
               '~'

rhs ::= precedenced_alternative { '||' precedenced_alternative }

precedenced_alternative ::= alternative { '|' alternative }

alternative ::= rhs_primaries { ',' adverb }

adverb ::= action |
           completed |
           predicted |
           assoc

-- values other than function(...) -- https://github.com/rns/kollos-luif-doc/issues/12
-- context in action functions -- https://github.com/rns/kollos-luif-doc/issues/11
action ::= 'action' '=' functionexp

completed ::= 'completed' '=' functionexp

predicted ::= 'predicted' '=' functionexp

functionexp ::= 'function' funcbody |
                Name

assoc ::= 'assoc' '=' assocexp

assocexp ::= 'left' |
             'right' |
             'group'

rhs_primaries ::= { rhs_primary }       -- can be empty, like Lua chunk

rhs_primary ::= separated_sequence |
                symbol_name |
                literal |
                charclass |
                grouped_alternative |
                hidden_alternative

separated_sequence ::= sequence  |
                       sequence '%'  separator | -- proper separation
                       sequence '%%' separator |
                       sequence '%-' separator |
                       sequence '%$' separator

grouped_alternative ::= '(' alternative ')'

hidden_alternative ::= '[' alternative ']'

sequence ::= sequence_item '+' |
             sequence_item '*' |
             sequence_item '?' |
             sequence_item '**' Number '..' Number |
             sequence_item '**' Number '..' '*'

sequence_item ::= symbol_name |
                  grouped_alternative |
                  hidden_alternative

separator ::= symbol_name |
              literal |
              character_class

symbol_name :: Name

literal ::= String    -- sans the long strings

character_class ::= String

```
[todo: `character_class` as sequence separator is [under discussion](https://github.com/rns/kollos-luif-doc/issues/17#issuecomment-98474355)]

[todo: implementation detail: Lua patterns can be much slower than regexes, so we can
use lua patterns as they are or
translate them to regexes for speed
or make this an option ]

<a id="example_grammars"></a>
## Example grammars

<a id="calculator"></a>
### Calculator

```
Script ::= Expression+ % ','
Expression ::=
  Number
  | '(' Expression ')', assoc = group, action = do_parens
 || Expression '**' Expression, assoc = right, action = function (e1, e2) return e1 ^ e2 end
 || Expression '*' Expression, action = function (e1, e2) return e1 * e2 end
  | Expression '/' Expression, action = function (e1, e2) return e1 / e2 end
 || Expression '+' Expression, action = function (e1, e2) return e1 + e2 end
  | Expression '-' Expression, action = function (e1, e2) return e1 - e2 end
 Number ~ [0-9]+
```

<a id="json"></a>
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
