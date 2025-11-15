# Rubysyn: clarifying Ruby's syntax and semantics

**[WIP, 2025-11-15]** This is an experiment in clarifying some aspects
of Ruby syntax and semantics.  For that we're going to introduce an
alternative Lisp-based syntax for Ruby, preserving Ruby semantics.

The goal is to define a comprehensive, trivially-parsable and
sugar-free syntax.

As I started working on this, I had to find a better explanation for
some aspects of Ruby than what is available in standard documentation.
So we also discuss some aspects of standard Ruby syntax and semantics.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Array literals: full version](#array-literals-full-version)
  - [Desugaring constructing array splat](#desugaring-constructing-array-splat)
  - [\[\] is also a sugar](#-is-also-a-sugar)
  - [Rubysyn: `(array)`](#rubysyn-array)
  - [Rubysyn: `(array-splat)`](#rubysyn-array-splat)
- [Single-variable assignment](#single-variable-assignment)
  - [Desugaring automatic array creation in assignment](#desugaring-automatic-array-creation-in-assignment)
  - [Variable declaration vs assignment](#variable-declaration-vs-assignment)
  - [Rubysyn: `(var)`](#rubysyn-var)
  - [Rubysyn: `(assign)`](#rubysyn-assign)
- [Multi-variable assignment](#multi-variable-assignment)
  - [Desugaring automatic array creation in multi-assignment](#desugaring-automatic-array-creation-in-multi-assignment)
  - [Splat variable](#splat-variable)
  - [Bare splat variable](#bare-splat-variable)
  - [Rubysyn: `(assign-multi)`](#rubysyn-assign-multi)
- [Logical operators](#logical-operators)
  - [Rubysyn: `(not)`](#rubysyn-not)
- [Control flow](#control-flow)
  - [Rubysyn: `(seq)`](#rubysyn-seq)
  - [Rubysyn: `(if)`](#rubysyn-if)
    - [Desugaring `if` variants](#desugaring-if-variants)
  - [Rubysyn: `(while)`](#rubysyn-while)
- [Rubysyn: literals](#rubysyn-literals)
  - [String literals](#string-literals)


<!-- markdown-toc end -->


## Array literals: full version

For some reason, the standard documentation does not explain full
syntax of array literals.

Most common case of array literals is extremely well known:

* empty array: `[]`;

* array of three elements: `[1, 2, 3]`;

* string-array literals: `%w(...)` and `%W(...)`;

* symbol-array literals: `%i(...) and `%i(...)`;

Additionally, array literals support so called "constructing array
splat" syntax:

````ruby
[1, 2, *foo, 3]
````

The asterisk before the value replaces it with zero or more values,
depending on what is in `foo`:

* if `foo` is an array, `*foo` is replaced by its elements:

```ruby
foo = [10, 11]
[1, 2, *foo, 3]

# [1, 2, 10, 11, 3]

```

* if `foo` responds to `to_a` method, that method is called, and
  `*foo` is replaced by the result array (see below for some
  examples);

* finally, for all other values `*foo` is replaced by the value of
`foo`:

```ruby
foo = "hello"
[1, 2, *foo, 3]

# [1, 2, "hello", 3]

```

### Default implementations of `#to_a`.

Particularly, `nil.to_a` returns an empty array:

```ruby
foo = nil
[1, 2, *foo, 3]

# [1, 2, 3]
```

If `foo` is a hash, `*foo` is replaced by a list of two-element
arrays, one for each hash key:

```ruby
foo = { foo: :bar, quux: 23 }
[1, 2, *foo, 3]

# [1, 2, [ :foo, :bar ], [ :quux, 23 ], 3]

```

### Constructing array splat syntax is underdocumented

For some reason, this is not explained in standard Ruby documentation:

* ["Creating Arrays"](https://docs.ruby-lang.org/en/3.4/Array.html#class-Array-label-Creating+Arrays);

* ["Array Literals"](https://docs.ruby-lang.org/en/3.4/syntax/literals_rdoc.html#label-Array+Literals);

This syntax is used in the
["Implicit Array Assignment"](https://docs.ruby-lang.org/en/3.4/syntax/assignment_rdoc.html#label-Implicit+Array+Assignment)
section, but in a very confusing way (more on that below).

This syntax has nothing to do with assignment, it works everywhere
where you use array literals.  NB: Do not confuse it with
"destructuring array splat" syntax which is very much different, see
below.

### Desugaring constructing array splat

Constructing array splat is pure syntactic sugar.  You can easily
implement it as a simple Ruby function:

```ruby
def array_splat(arr, chunk)
  case
  when chunk.is_a?(Array)
    return arr.concat(chunk)
  when chunk.respond_to?(:to_a)
    tmp = chunk.to_a
    if tmp.is_a?(Array)
      return arr.concat(tmp)
    else
      raise TypeError.new("can't convert #{chunk.class} to Array (#{chunk.class}#to_a gives #{tmp.class}) (TypeError)")
    end
  else
    return arr.append(chunk)
  end
end
```

Note that the semantics of this function has only been specified in
the standard documentation very recently:
["Unpacking Positional Arguments"](https://docs.ruby-lang.org/en/master/syntax/calling_methods_rdoc.html#label-Unpacking+Positional+Arguments).
Also, there does not seem to exist a function with the same semantics
as `array_splat`.

### [] is also a sugar

Note that `[]` is itself a sugar for `Array#[]` method:

```ruby
Array.[](2, 3, 4)
# [2, 3, ]
```

So it's possible that constructing array splat actually stems from
function argument processing.

However, for now we consider array literal suffix an independent
syntactical construct.

### Rubysyn: `(array)`

Having considered all that, we realize that we need to handle only the
most trivial case, everything else is a syntax sugar.

```lisp
(array <value>...)

```

Here are some examples:

| Ruby | Rubysyn |
|------|---------|
| `[]` | `(array)` |
|`[ 1, 2, 3 ]` | `(array 1 2 3)` |

### Rubysyn: `(array-splat)`

We also define the `array-splat` function with the same semantics as
`def array_splat` defined above.

```lisp
(array-splat arr chunk)
```

Here are some examples:

| Ruby | Rubysyn |
|------|---------|
| `[1, 2, *foo]` | `(array-splat (array 1 2) foo)` |
|`[ 3, 4, *bar, 5, 6 ]` | `(array-splat (array-splat (array 3 4) bar) (array 5 6))` |


## Single-variable assignment

Single-variable assignment has a very simple base syntax:

```ruby
a = 3
# 3

```

### Desugaring automatic array creation in assignment

On the right side of the equals sign there is always a single
expression, but there is an extra syntax sugar that automatically
creates arrays from comma-separated expressions.

```ruby
a = 3, 4, 5
# [3, 4, 5]

```

This is completely equivalent to the usual:

```ruby
a = [3, 4, 5]
# [3, 4, 5]
```

Another way to trigger automatic creation of arrays is to use a constructing array splat syntax:

```ruby
a = *3
# [3]

```

This is completely equivalent to:

```ruby
a = [3]
# [3]
```

### Variable declaration vs assignment

Variable assignment automatically declares variable in the current
binding, if it was not already declared.

Newly-declared variables have a value of `nil`.

We'll clarify what "binding" means below.

Note that the right-hand side of assignment is executed after the
left-hand variable was declared and initialized to `nil`.  For example:

```ruby
a = a
# nil

b = b.class
# NilClass

```

### Rubysyn: `(var)`

Having considered all of this, we decouple variable declaration from variable assignment.

```lisp
(var <var>)

```

Declares listed variables in the current binding and initializes them to `nil`.

`(var)` also returns `nil`.

```lisp
(var a)
# nil

```

### Rubysyn: `(assign)`

`(assign var value)` assigns a single value to a single variable.  Variable must
be declared by `(var)`, otherwise a runtime exception is raised.


`(assign)` returns a `value` as the result.

Example:

```lisp
(var a)
(assign a 3)
# 3

```

## Multi-variable assignment

Multi-variable assignment seems to be a completely different construct
compared to single-variable assignment.

```ruby
a, b, c = 1, 2, 3
# [1, 2, 3]

[a, b, c]
# [1, 2, 3]
```

On the left side of assignment operator (`=`) there is a list of two
or more variable names.  Note that variables do not need to be unique:

```ruby
a, a, a = 1, 2, 3
# [1, 2, 3]

a
# 3
```

On the right side of assignment operator there is always an array of
values.  The size of that array can be arbitrary and may not match the
number of variables.

### Desugaring automatic array creation in multi-assignment

On the right side of the equals sign there is always a single array
value.  There is also an extra syntax sugar that automatically creates
arrays from comma-separated values.  Additionally, a single non-array
value is converted to a one-element array.

```ruby
a, b, c = 3, 4, 5
# [3, 4, 5]

[a, b, c]
# [3, 4, 5]
```

This is completely equivalent to:

```ruby
a, b, c = [3, 4, 5]
# [3, 4, 5]

[a, b, c]
# [3, 4, 5]
```

Single non-array value is almost equivalent to a one-element array,
only the return value of the operator itself is different:

```ruby
a, b, c = 1
# 1

[a, b, c] = [1, nil, nil]

a, b, c = [1]
# [1]

[a, b, c] = [1, nil, nil]

```

Constructor array splat syntax works the same way as in single-variable assignment.

```ruby
foo = [2, 3]
a, b, c = 1, *foo
# [1, 2, 3]

[a, b, c]
# [1, 2, 3]

```

### Mismatch between the number of variables and the number of values

If there are fewer variables than values, unused values are ignored.

```ruby
a, b = [1, 2, 3]
# [1, 2, 3]

[a, b]
# [1, 2]
```

If there are more variables than values, extra variables are set to `nil`.

```ruby
a, b, c = [1, 2]
# [1, 2]

[a, b, c]
# [1, 2, nil]

```

### Variable declaration in multi-assignment

Assignment operator works in several steps. First, all variables are
added to the current binding, unless they are already declared.

Second, the right-hand array values are evaluated, using the current binding.

Third, the variables are bound to evaluated values.  (This part is
intentionally vague, to be clarified later.)

This allows us to swap to variables without using the third, for example:

```ruby
a = 1
b = 2

a, b = b, a

[a, b]
# [2, 1]

```

Also, just-declared variables could be used on the right-hand side:

```ruby
a, b = b, 1
# [nil, 1]

[a, b]
# [nil, 1]

```

### Splat variable

One, and only one variable on the left hand side could be marked with
a special "`*`" (asterisk) syntax.  This variable will get assigned an
array value that contains all values left after other variables are
assigned.

```ruby
a, b, *c, d = 1, 2, 3, 4, 5, 6, 7
# [1, 2, 3, 4, 5, 6, 7]

[a, b, c, d]
# [1, 2, [3, 4, 5, 6], 7]

```

See that `a` got assigned the first value, `b` got assigned the second
value, and `d` got assigned the last value.  Remaining values were put
into the array and assigned to splat variable `c` (`[3, 4, 5, 6]`).

Normal variables get assigned first, splat variable is assigned last.

If there is not enough values, splat variables will get assigned an empty array.


```ruby
a, *b, c = 1, 2
# [1, 2]

[a, b, c]
# [1, [], 2]

```

If there is not enough values even for normal variables, they will get
assigned `nil`, as usual.

There could be no values at all:

```ruby
a, *b, c = []
# []

[a, b, c]
# [nil, [], nil]
```

### Bare splat variable

There is a special syntactic case that at the moment may be too
tediuos to incorporate into general rules of multi-assignment.

One splat variable without any other variables is also a variant of
multi-assignment.

```ruby
*a = 1, 2, 3
# [1, 2, 3]

a
# [1, 2, 3]

```

It is a multi-assignment because the splat variable still receives an
array, even when there is only one value on the right hand side:

```ruby
*a = 1
# 1

a
# [1]

```

### Rubysyn: `(assign-multi)`

In Rubysyn, multi-assignment looks like this:

```lisp
(assign-multi var1... expr)

```

Splat variable is marked by `(splat-var var)`;

```lisp
(assign-multi a (splat-var b) c (array 1 2 3))

```

It seems that `(assign-multi)` is not a proper Lisp function, but a syntactic
macro that generates the code that:

* declares and initializes variables to be assigned;

* uses temporary variables to evaluate and store right hand side values;

* assigns temporary variables;

* returns the *expr* as a result;

Later we'll see that the "assigns temporary variables" step can look
differently depending on the type of assignment.

## Logical operators

### Rubysyn: `(not)`

`(not <expr>)` implements logical operator NOT.  It evaluates
`<expr>`, and returns `true` if the value is `false` or `nil`, and
`false` otherwise.

This corresponds to Ruby operator `not`.

Note that Ruby operator `!` is different, see "Method-based operators".

Fun fact: `not` is not described in the standard Ruby documentation:
["Logical Operators"](https://docs.ruby-lang.org/en/3.4/syntax/operators_rdoc.html#label-Logical+Operators).

## Control flow

### Rubysyn: `(seq)`

`(seq <expr>...)` implements simple execution sequence.  Provided
expressions are evaluated one by one.  If the control flow reached the
end of `(seq)`, the value of last element is returned as the result.

`(seq)` corresponds to the almost invisible syntax in Ruby: new lines
and semicolons
(see ["Ending an Expression"](https://docs.ruby-lang.org/en/3.4/syntax/miscellaneous_rdoc.html#label-Ending+an+Expression)).

Empty `(seq)` is a no-op.  It returns `nil` as the result.

### Rubysyn: `(if)`

`(if <expr> <true-branch> [<false-branch>])` implements `if` operator as defined in Ruby.

First, an `<expr>` is evaluated.  If its value is true,
`<true-branch>` is executed and its value is returned as the result.
If the `<false-branch>` exists, all the `(var)` variable declarations
are gathered from its body, and executed.

Otherwise, if the value is false and `<false-branch>` exists, it is
executed and its value is returned as the result.  Before returning,
all the `(var)` variable declarations are gathered from
`<true-branch>` body, and executed.

All of this is needed because in variable declarations in Ruby are
valid even if they are in the branch that was never taken.  E.g.:

````ruby

if true
  # do nothing
else
  a = 2
end

a
# => nil

````

Here the `a` variable is declared even though the "else" branch of
this `if` was never taken.  This syntax is recursive: you can define
more `if`'s and other constructs in a never-taken branch, and all of
those variables would be declared after the end of the top-level `if`.

In Rubysyn this code corresponds to:

```lisp

(if true (seq)
    (seq (var a) (assign a 2)))

a
;; => nil
````

In this example, we can analyze the "else" branch and see that it
contains a declaration of `a` variable.  This analysis is completely
static and works on a syntax level.  The original code is rewritten
like this:

```lisp

(if true (seq (var a))  ;; <--- (var a) inserted here
    (seq (var a) (assign a 2)))

a
;; => nil
````

This "declaration gathering" is explained in more detail below.

#### Desugaring `if` variants

Ruby ternary operator `a ? b : c` is implemented as `(if a b c)`.

`elsif` is equvalent to `else if`.

`unless` is equivalent to `if not`.

### Rubysyn: `(while)`

`(while cond body)` implements the `while` operator as defined in Ruby.

First, a `<cond>` is evaluated.  If its value is true, `<body>` is
executed. After that `<cond>` is evaluated again, and the cycle
repeats.

Additionally, all the `(var)` variable declarations are gathered from
body, and executed.

All of this is needed because variable declarations in Ruby are
valid even if the loop body was never executed.  E.g.:

```ruby

while false
  a = 2
end

a
# => nil

```

"Declaration gathering" is explained in more detail below.

Normally, `(while)` returns `nil`.  `(break)` operator, described
below, can override this.



## Rubysyn: Literals

### String literals

String literals in Rubysyn are double-quoted.  Only a small number of
escape sequences is supported: `\"`, `\\`, `\n`, `\r`, `\t`,
`\u{nnnnn}`, and `\xnn`.  Other symbols after backslash are not
allowed.

All other Ruby syntax for string construction, including
here-documents etc. is a syntactic sugar and is not supported.

Example:

````lisp
(var foo)
(assign foo "Hello, world!")

````

String interpolation is implemented as a helper function:

````lisp
(string-interpolate "<template>" <value>...)

````

`<template>` is a string literal with two active components: `%s` and
`%%`.  All other symbols after percent sign are not allowed.

For each value a `#to_s` method is called, and the resulting value is
inserted into a template.

String literals correspond to instances of class `String`.  We discuss
memory allocation of such instances elsewhere.
