# The LUIF

Warning: the below is an unedited draft/skeleton, mostly wrapping up what's been done so far for further work.

## Overview

This document desribes the LUIF (LUa InterFace), 
the interface language of 
the [Kollos project](https://github.com/jeffreykegler/kollos/). 

The LUIF is Lua, extended with [BNF](http://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form) statements.

[todo: consider rearranging the sections after more content is added 
to follow the Lua manual bottom-up pattern of introducing individual constructs with grammar snippets first and presenting the full syntax in the final section. ]

## BNF statement

There is only one BNF statement, combining precedence, sequences, and alternation.

LUIF extends the Lua syntax by adding `bnf` and `grammarexp` alternatives to, accordingly, `stat` and `exp` rules of the [Lua grammar](http://www.lua.org/manual/5.1/manual.html#8) and introducing the new rules. The general syntax for a BNF statement is

[todo: convert the below SLIF syntax to EBNF used by Lua manual]

[todo: make sure it conforms to other sections]

```
stat ::= BNF

BNF ::= <BNF rule>+

exp ::= grammarexp

grammarexp ::= <grammar> grambody

grambody ::= <left paren> parlist <right paren> block <end>
grambody ::= <left paren> <right paren> block <end>

# There is only one BNF statement,
# combining priorities, sequences, and alternation
<BNF rule> ::= lhs '::=' <prioritized alternatives>
<prioritized alternatives> ::= <prioritized alternative>+ separator => <double bar>
<prioritized alternative> ::= <alternative>+ separator => <bar>
<alternative> ::= rhs | rhs ',' <alternative fields>
<alternative fields> ::= <alternative field>+ separator => comma
<alternative field> ::= field | action
action ::= 'action' '(' <action parlist> ')' block <end>
<action parlist> ::= <symbol parameter> | <action parlist> ',' <symbol parameter>
<symbol parameter> ::= <named RH symbol>
  | <named RH symbol> '[' <nonnegative integer> ']'
  | <named RH symbol> '[]'

<named RH symbol> ::= <named symbol>
lhs ::= <named symbol>

<double bar> ~ '||'
bar ~ '|'
comma ~ ','

rhs ::= <RH atom>+
<RH atom> ::=
     '[]' # for empty symbol
   | <separated sequence>
   | <named symbol>
   | '(' alternative ')'
   | '[' alternative ']'

# The sequence notation is extended to counted sequences,
# and a separator notation adopted from Perl 6 is used

<named symbol> ::= <symbol name>
<separated sequence> ::=
      sequence
| sequence '%' separator # proper separation
| sequence '%%' separator # Perl separation

separator ::= <named symbol>

sequence ::=
     <named symbol> '+'
   | <named symbol> '*'
   | <named symbol> '?'
   | <named symbol> '*' <nonnegative integer> '..' <nonnegative integer>
   | <named symbol> '*' <nonnegative integer> '..' '*'

# symbol name is any valid Lua name, plus those with
# non-initial hyphens
# TODO: add angle bracket variation
#<symbol name> ~ [a-zA-Z_] <symbol name chars>
#<symbol name chars> ~ [-\w]*
<symbol name> ::= Name

#<nonnegative integer> ~ [\d]+
<nonnegative integer> ::= Number

# <symbol name>, <symbol name chars>, <nonnegative integer> rules
# are commented out from Jeffrey Kegler's BNF because
# MarpaX::Languages::Lua::AST::extend() doesn't support character classes.
# For the moment, suitable tokens from Lua grammar (Name and Number) are used instead
# TODO: charclasses

```

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

[todo: update the LUIF grammar according to the below description]
A LUIF symbol name is any valid Lua name.
In addition, names with non-initial hyphens are allowed.
Eventually an angle bracket notation for LUIF symbol names,
similar to that of 
the [SLIF](https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod#Symbol-names),
will allow whitespace
in names.

### Literals

### Character classes

### Comments

### Adverbs

#### action

## Post-processing

The output of the KHIL will be a table, with one key for each grammar name.  Keys *must* be strings.  The value of each grammar key will be a table, with entries for external and internal symbols and rules.  Details of the format will be specified later.

This table will be interpreted by the lower layer (KLOL).  Initially post-processing will take a very restricted form in the LUIF grammars.   There are two kinds of Libmarpa grammars: structural and lexical grammar.  A grammar is lexical if one or more of its rules have the special `lexeme` action.  The post-processing will expect a lexical grammar named `l0` and a structural grammar named `g1`, and will check (in the same way that Marpa::R2 currently does) to ensure they are compatible.

## Grammars

BNF statements are grouped into one or more grammars.  The grammar is indicated by the produce-operator of the 
BNF.  Its general form is `:grammar:=`, where `grammar` is the name of a grammar.  `grammar` must not contain colons.  Initially, the post-processing will not support anything but `l0` and `g1` used in the default way.

If the produce-operator is `::=`, then the grammar is `g1`.  The tilde `~` can be a produce-operator, in which case it is equivalent to `:l0:=`.

A structural grammar will often contain lexical elements, such as strings and character classes, and these will go into its linked lexical grammar.  The start rule specifies its lexical grammar with an adverb (what?).  In a lexical grammar the lexemes are indicated with the `lexeme` adverb -- if a rule has a lexeme adverb, its LHS is a lexeme.

If a grammar specified lexemes, it is a lexical grammar.  If a grammar specified a linked lexical grammar, it is a structural grammar.  `l0` must always be a lexical grammar.  `g1` must always be a structural grammar and is linked by default to `l0`.  It is a fatal error if a grammar has no indication whether it is structural or lexical, but this indication may be a default.  Enforcement of these restrictions is done by the lower layer (KLOL).  `

## Example grammars

### Calculator

[todo: convert to valid LUIF]

```
    Script ::= Expression+ % comma
    Expression ::=
      Number
      | left_paren Expression right_paren
     || Expression exp Expression
     || Expression mul Expression
      | Expression div Expression
     || Expression add Expression
      | Expression sub Expression
```

### JSON

[todo: convert to valid LUIF]

```
            json         ::= object
                           | array
            object       ::= [lcurly rcurly]
                           | [lcurly] members [rcurly]
            members      ::= pair+ % comma
            pair         ::= string [colon] value
            value        ::= string
                           | object
                           | number
                           | array
                           | true
                           | false
                           | null
            array        ::= [lsquare rsquare]
                           | [lsquare] elements [rsquare]
            elements     ::= value+ % comma
            string       ::= lstring
            lcurly ~ '{'
            rcurly ~ '}'
            lsquare ~ '['
            rsquare ~ ']'
            lstring
```

