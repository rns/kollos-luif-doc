# The LUIF

Warning: this is a working draft.

## Overview

This document describes the LUIF (LUa InterFace),
the interface language of
the [Kollos project](https://github.com/jeffreykegler/kollos/).

The LUIF is Lua, extended with [BNF](http://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form) statements.

[todo: consider rearranging the sections after more content is added
to follow the Lua manual bottom-up pattern of introducing individual constructs with grammar snippets first and presenting the full syntax in the final section. ]

## BNF statement

There is only one BNF statement, combining precedence, sequences, and alternation.

LUIF extends the Lua syntax by adding `bnf` alternative to `stat` rule of the [Lua grammar](http://www.lua.org/manual/5.1/manual.html#8) and introducing the new rules. The general syntax for a BNF statement is as follows (`stat`, `block`, `funcname`, `funcbody`, `var`, `Name`, and `String` symbols are as defined by the Lua grammar):

Note: this describes LUIF structural and lexical grammars 'used in the default way' as defined in [Grammars](#grammars) section below. The first rule will act as the start rule.

[todo: make sure it conforms to other sections]

```
stat ::= bnf

bnf ::= lhs produce_op rhs  -- to make references to LHS/RHS easier to understand

lhs ::= symbol_name

produce_op ::= '::=' |
               '~'

rhs ::= precedenced_alternative { '||' precedenced_alternative }

precedenced_alternative ::= alternative { '|' alternative }

alternative ::= rhslist { ',' adverb }

adverb ::= action |
           completed |
           predicted |
           assoc

-- values other than function(...) -- https://github.com/rns/kollos-luif-doc/issues/12
-- context in action functions -- https://github.com/rns/kollos-luif-doc/issues/11
action ::= 'action' '=' functionexp

completed ::= 'completed' '=' functionexp

predicted ::= 'predicted' '=' functionexp

functionexp ::= 'function' funcname funcbody |
                funcname

assoc ::= 'assoc' '=' assocexp

assocexp ::= 'left' |
             'right' |
             'group'

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

-- more complex separators -- http://irclog.perlgeek.de/marpa/2015-05-03#i_10538440
separator ::= symbol_name

sequence ::= symbol_name '+' |
             symbol_name '*' |
             symbol_name '?' |
             symbol_name '*' Number '..' Number |
             symbol_name '*' Number '..' '*'

symbol_name :: Name

literal ::= String    -- long strings not allowed

-- a Lua pattern as per http://www.lua.org/manual/5.1/manual.html#5.4.1
-- or a regex character class
charclass ::= String

```

[todo: implementation detail: Lua patterns can be much slower than regexes, so we can
use lua patterns as they are or
translate them to regexes for speed
or make this an option ]

[todo: nested delimiters as sequence separators,
like [`%bxy`](http://www.lua.org/pil/20.2.html), but with nesting support
per comment to https://github.com/rns/kollos-luif-doc/issues/17]

### Sequences

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
    %% <sep>     -- use <sep> as liberal separator
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

[ Character classes are *not* patterns or regexes -- they are
the portion of the regex/pattern syntax that describes a
*single* character.  For example `[abc]` and not `a*` or even
`abc`. ]

[todo: string containing a Lua pattern?  I'd like to restrict the
charclasses to those allowed by Lua patterns. ]

[todo: string containing a PCRE regex? rename to Regexes then]

### Comments

LUIF comments are Lua comments as defined at the end of [Lexical Conventions](http://www.lua.org/manual/5.1/manual.html#2.1) section in the Lua 5.1 Reference Manual.

### Adverbs

#### `action` <a id="action"></a>

The `action` adverb defines the semantics of its RHS alternative.
Its values are specified in [Semantics](#semantic_action) section below.

#### `completed` <a id="completed"></a>

The `completed` adverb defines
the Lua function to be called when the RHS alternative is completed during the parse.
Its values are the same as those of the `action` adverb.

For more details on parse events, see [Events](#events) section.

#### `predicted` <a id="predicted"></a>

The `predicted` adverb defines
the Lua function to be called when the RHS alternative is predicted during the parse.
Its values are the same as those of the `action` adverb.

For more details on parse events, see [Events](#events) section.

#### `assoc`

The `assoc` adverb defines associativity of a precedenced rule.
Its value can be `left`, `right`, or `group`.
The function of this adverb is as defined in the [SLIF](https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod#assoc).

## Semantics <a id="semantic_action"></a>

The semantics of a BNF statement in the LUIF can be defined using either [`action` adverb](#semantic_action) of its RHS alternative or the [Abstract-Syntax Forest (ASF)](#semantics_with_ast_asf) functions of the LUIF.

### Defining Semantics with `action` <a id="semantic_action"></a> adverb

The value of the `action` adverb can be a Lua function as defined in [Function Definitions](http://www.lua.org/manual/5.1/manual.html#2.5.9) section of the Lua 5.1 Reference Manual or the name of such function.

An action function can be
a [bare function](#bare_function),
a [namespaced function](#namespaced_function), or
a [method](#method_function).
This allows defining semantics in a set of functions, a namespace (Lua package) or an object.
The action functions will be called in the context where their respective BNF statements are defined. Their return values will become the values of the LHS symbols corresponding to the RHS alternatives modified by the `action` adverb.

The match context information, such as
matched rule data, input string locations and literals
will be provided by [context accessors](#context_accessors) in `luif.context` namespace.

If the semantics of a BNF statement is defined in a separate Lua file, LUIF functionality must be imported with Lua's [`require`] (http://www.lua.org/manual/5.1/manual.html#pdf-require) function.

#### Bare Function Actions <a id="bare_function"></a>

The syntax for a bare function action is

```lua
action = function f (params) body end
```

It will be called as `f (params)`
with `params` set to
the values defined by the semantics of the matched RHS alternative's symbols.

#### Namespaced Function Actions <a id="namespaced_function"></a>

The syntax for a namespaced function action is

```lua
action = function t.a.b.c.f (params) body end
```

It will be called as `t.a.b.c.f (params)`
with `params` set to
the values defined by the semantics of the matched RHS alternative's symbols.

More details on packages in Lua can be found in [Packages](http://www.lua.org/pil/15.html) section of _Programming in Lua_ book.

#### Method Actions <a id="method_function"></a>

The syntax for a method action is

```lua
action = function t.a.b.c:f (params) body end
```

or

```lua
action = function t.a.b.c.f (self, params) body end
```

It will be called as `t.a.b.c:f (params)`
with `params` set to
the values defined by the semantics of the matched RHS alternative's symbols.

More details on objects and methods in Lua can be found in [Object-Oriented Programming](http://www.lua.org/pil/16.html) section of _Programming in Lua_ book.

#### Context Accessors <a id="context_accessors"></a>

Context accessors live in the `luif.context` name space.
They can be called from semantic actions to get matched rule and locations data.
To import them into a separate file, use Lua's [`require`](http://www.lua.org/manual/5.1/manual.html#pdf-require) function, i.e.

```lua
require 'luif.context'
```

The context accessors are:

##### `lhs_id = luif.context.lhs()`

returns the integer ID of the symbol which is on the LHS of the BNF rule matched in the parse value or completed/predicted during the parse.

##### `rule_id = luif.context.rule()`

returns the integer ID of the BNF rule matched in the parse value or completed/predicted during the parse.

##### `alt_no = luif.context.alternative()`

returns the number of the the BNF rule's RHS alternative matched in the parse value or completed/predicted during the parse.

##### `prec = luif.context.precedence()`

returns numeric precedence of the matched/completed/predicted alternative
relative to other alternatives or nil if no precedence is defined for the alternative.

##### `pos, len = luif.context.span()`

returns position and length of the input section corresponding to
the BNF rule matched in the parse value or
completed/predicted during the parse.

##### `string = luif.context.literal()`

returns the section of the input corresponding to
the BNF rule matched in the parse value or
completed/predicted during the parse.
It is defined by
the input span returned by the `luif.context.span()` function above.

##### `pos = luif.context.pos()`

returns the position in the input, which starts the span corresponding to
the BNF rule matched in the parse value or
completed/predicted during the parse.

##### `len = luif.context.length()`

returns the length of the input span corresponding to
the BNF rule matched in the parse value or
completed/predicted during the parse.

### Defining Semantics with AST/ASF <a id="semantics_with_ast_asf"></a>

Marpa is designed to support ambiguity out-of-the-box,
hence the LUIF semantics aims for the general case, where you have several parse values (ambiguous parse) and treats single parse values (unambiguous parse) as its specialization.
The former case is handled with the [Abstract Syntax Forest (ASF) interface](#asf_traversal), while for the latter the application can simply [walk the AST](#ast_walking).

The application can use `luif.value.ambiguous()` function to determine whether the parse is ambiguous. [todo: specify `luif.value.ambiguous()`]

#### Ambiguous Parse -- Traversing the ASF  <a id="asf_traversal"></a>

If the parse is ambiguous,
LUIF walks the ASF calling the traverser function for its nodes.
The traverser can call functions in `luif.asf` interface to enumerate and/or prune parse alternatives. This is done with `luif.asf.traverse(traverser)` function.

[todo: more details/examples on ASF traversal]

##### Enumerating Parse Alternatives

##### Pruning the ASF

#### Unambiguous Parse -- Walking the AST <a id="ast_walking"></a>

If the parse is unambiguous, the ASF becomes the AST that makes the application's job much simpler. LUIF will build the AST and will call the visitor function for its nodes in the given order. The application can use [context accessors](#context_accessors) to get the node data, distill the AST, and produce the parse value. This is done by calling `luif.ast.walk(order, visitor)` function.

[todo: more details/examples on AST walking]

### Actions and ASF's: How to Choose

[todo: more meaningful example/considerations are required
for this section is it is at all needed]

In addition to user preferences,
the choice between actions and ASFs can be defined
by how context-sensitive the input is, i.e.
how much context information is needed to build the parse value.

As an arguably trivial example, if the parse value must be produced
by computing an arithmetic expression, actions become the obvious choice.

As a less trivial example, in the case of syntax-driven translation,
where the value of each symbol is context-independent,
actions or even events provide a better choice.

On the other hand, nested macro expansion
can arguably be done more convenient with the full context at hand
so the full AST (ASF) is required.

## Events <a id="events"></a>

Parse events are defined using [`completed`](#completed) and [`predicted`](#predicted) adverbs.

[todo: provide getting started info/tutorial on parse events].

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

If a grammar specifies lexemes, it is a lexical grammar.  If a grammar specifies a linked lexical grammar, it is a structural grammar.  `l0` must always be a lexical grammar.  `g1` must always be a structural grammar and is linked by default to `l0`.  It is a fatal error if a grammar has no indication whether it is structural or lexical, but this indication may be a default.  Enforcement of these restrictions is done by the lower layer (KLOL).

## Example grammars

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
