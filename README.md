# Rubysyn: clarifying Ruby's syntax and semantics

**[WIP, 2026-04-01]** This is an experiment in clarifying some aspects
of Ruby syntax and semantics.  For that we're going to introduce an
alternative Lisp-based syntax for Ruby, preserving Ruby semantics.

The goal is to define a comprehensive, trivially-parsable and
sugar-free syntax.

As I started working on this, I had to find a better explanation for
some aspects of Ruby than what is available in standard documentation.
So we also discuss some aspects of standard Ruby syntax and semantics.

See the `spec/` directory for some corner cases of Ruby syntax and
semantics that we are interested here.

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
- [Semantic primitives](#semantic-primitives)
  - [Synvars](#synvars)
  - [Tailcalls and labels](#tailcalls-and-labels)
- [Control flow](#control-flow)
  - [Rubysyn: `(seq)`](#rubysyn-seq)
  - [Rubysyn: `(if)`](#rubysyn-if)
    - [Desugaring `if` variants](#desugaring-if-variants)
  - [Rubysyn: `(while)`](#rubysyn-while)
  - [Rubysyn: `(break)`, `(next)`, and `(redo)`](#rubysyn-break-next-and-redo)
- [Blocks and lambdas](#blocks-and-lambdas)
  - [Rubysyn: `(lambda)`](#rubysyn-lambda)
  - [Rubysyn: `(call)`](#rubysyn-call)
    - [Runtime behavior of `(call)`](#runtime-behavior-of-call)
  - [Rubysyn: `(return)`](#rubysyn-return)
- [Classes, modules and methods](#classes-modules-and-methods)
  - [Rubysyn: `(class)`](#rubysyn-class)
  - [Rubysyn: `(singleton-class)`](#rubysyn-singleton-class)
  - [Rubysyn: Modules](#rubysyn-modules)
  - [`self`](#self)
  - [`include`](#include)
  - [`def`](#def)
  - [`(send)`](#send)
  - [Rubysyn: operators syntax sugar](#rubysyn-operators-syntax-sugar)
- [Rubysyn: literals](#rubysyn-literals)
  - [String literals](#string-literals)
  - [Symbol literals](#symbol-literals)
  - [Hash literals](#hash-literals)


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

## Semantic primitives

Some constructs in Rubysyn do not correspond to anything in Ruby
syntax.  Those constructs help define the execution semantics.  We
define most of them with a lot of handwaving at the moment.

### Synvars

Synvars are "syntactic variables".  Synvars can store values of all
types: both internal and Ruby values.  Synvar names look like
`$$foo-bar-baz`.  They are not visible to Ruby itself, but their
values can be.

Some synvars are global and defined by the Rubysyn language.  Some
synvars are syntactic, and could be used freely to illustrate the
implementation of normal Rubysyn constructs.

Synvars could be assigned using `(assign)`.  Here are some examples
without explanation:

```lisp
(assign $$current-binding $$previous-binding)

(assign $$return-value foo)

(assign $$next-label $$current-return-label)

```

### Tailcalls and labels

Rubysyn allows to define labels.  Label is basically a pointer to the
following s-expression.  You can transfer control to the label: this
is called goto^W "tailcall".

Labels can have one associated variable, and the tailcall can pass the
value to the label.  This value is assigned to the associated variable
before the control transfer happens.  Associated variables can be
synvars or local variables.

Labels are declared by `(label synvar var)` operator.  Each label has
a corresponding synvar that is basically a pointer to the following
s-expression.

Tailscalls are executed by `(tailcall synvar value)`.

Here is an example:

```lisp

(seq (var counter)               ; # 1
    (assign counter 0)           ; # 2

    (label $$local-top counter)  ; # 3

    (if (< counter 5)            ; # 4
        (tailcall $$label-top (+ counter 1))) ; # 5
    counter)

```

In line 1, a local variable `counter` is declared.  In line 2, it is
set to 0. In line 3, a tailcall label is defined; it points to the
`(if)` in line 4.

In lines 4-5, if the `counter` is less then 5, tailcall to the
`$$local-top` label, assigning the value of `(+ counter 1)` to
`counter`.

In this example we know that tailcall assigns value to a known
variable.  Technically, we don't need a tailcall assignment here.  But
it's important that it's the label that decides which variable gets
assigned.


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

After the loop was completed, all the `(var)` variable declarations
are gathered from body, and executed.

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

#### Desugaring loop variants

`until cond` is a syntactic sugar for `while not cond`.

### Rubysyn: `(break)`, `(next)`, and `(redo)`

In Ruby, `break`, `next` and `redo` are closely associated with all
kinds of loops: `while`, `until`, `for`, and `.each`.

Their execution semantics, however, could be defined in a very
primitive way using Rubysyn primitives.

* `(break val)` is implemented as `(tailcall $$current-break-label val)`;

* `(next val)` is implemented as `(tailcall $$current-next-label val)`;

* `(redo val)` is implemented as `(tailcall $$current-redo-label val)`;

That's it.  Three synvars used here are global.  Containing constructs
such as `(while)` set the values of those labels correspondingly.

`(while cond body)` could be expanded roughly in the following way:


```lisp
(seq (synvar $$return-value)
    (assign $$current-break-label $$bottom-label)
    (assign $$current-next-label $$top-label)
    (assign $$current-redo-label $$top-label)
    (label $$top-label)
    (if cond (seq body (tailcall $$top-label)))
    (label $$bottom-label $$return-value)
    $$return-value)
```

This (probably incomplete) implementation of `(while)` sets the three
global synvars to the appropriate labels.  As a result:

* `(break)` transfers control to the end of `(while)`, setting its
return value (defined by `$$bottom-label`);

* `(redo)` and `(next)` are equivalent inside `(while)`: they both
  transfer control back to the top of the loop.

Later we'll discuss how `$$current-break-label` et al are assigned for
`yield`, and for the top level.  This will explain the behaviour of
`.each` and top-level syntax exception in Ruby.


## Blocks and lambdas

**NB: this chapter is incomplete and partly inaccurate.

Ruby has blocks and lambdas.

With lambdas:

* `return` and `break` exit from lambda;

* `redo` goes back to the beginning of lambda;

* strict handling of arguments;

With blocks:

* `return` and `break` exits from the lambda where this block was
  defined (syntactically); throws `LocalJumpError` if it was called
  outside of any lambda (to achieve this, store a Proc instance
  somewhere and calle it);

* lax handling of arguments: missing arguments are filled with `nil`,
  single argument of `Array` type is deconstructed if the block has
  more than one argument, extra arguments are ignored;

In both blocks and lambdas, full range of Ruby arguments is supported:
normal arguments and keyword arguments, default values and splat
arguments.  Also, implicit arguments (`it`, `_1`, `_2`, etc.) are
supported.

In Ruby, blocks and lambdas can be stored in variables as instances of
`Proc` type.

In Rubysyn, blocks and lambdas can be stored directly in synvars.
Also, an instance of `Proc` could be created that contains block or
lambda, and it could be stored in Ruby variables (or synvars).

Methods are implemented as lambdas, but there is additional name
resolution machinery that we'll talk about in a separate section.

### Rubysyn: `(lambda)`

Lambdas are defined with the following syntax:

```lisp

(lambda (args arg1...) (kwargs kwarg1...) body)

```

and

```lisp
(lambda (implicit-args) body)

```

Inside the `(args ...)` clause you can use the following:

* simple required argument: `a`;

* optional argument with default value: `(optional b <default>)`; if
  default value is omitted, `nil` is used;

* required array decomposition argument: `(array c d e)`, see below;

* rest argument: `(splat z)`, assembles everything into an array
  value; omit the argument name to ignore keyword arguments;

Same inside the `(kwargs ...)` clause, but the rest argument assembles
everything into a Hash.  Rest argument must be the last in `(kwargs)` clause.

`(args ...)` and `(kwargs ...)` clauses are optional.  They can also be empty.

Default argument values can refer to the values of previous arguments.

Inside the `(args ...)` clause, required and optional arguments, and
the rest argument can be defined only in a certain order:

* *required-args?*;

* *optional-args?*;

* *rest-arg?*

* *required-args-2?*.

Any component may not be present.  If both *optional-args* and
*rest-arg* are not present, then *required-args-2* is empty.

Here, *required-args* may be both simple and array decomposition arguments.

Here are some examples of possible combinations:

```lisp

;; ->(a, b = 20, *c) { [a, b, c] }
(lambda (args a (optional b 20) (splat c))
    (array a b c))

;; ->(d, e = 42, **f) { [d, e, f] }
(lambda (kwargs d (optional e 42) (splat f))
    (array d e f))

;; no arguments
;; ->() { "foo" }
(lambda "foo")

;; ignore keyword arguments
;; ->(**) { [] }
(lambda (kwargs (splat))
    (array))

;; accept keywords but do not accept any keywords
;; ->(**nil) { [] }
(lambda (kwargs)
    (array))

```

Array decomposition arguments correspond to one function argument, but
may decompose into several identifiers.  Here is an example in Ruby:

```ruby
def foo(a, (b, c))
  a + b + c
end

foo(1, [20, 30])
 # => 51
```

As you can see, `foo` accepts two arguments (`1` and a two-element
array), but there are three identifiers that you could use in the
method body.

In Rubysyn such a lambda is defined like this:

```lisp
(lambda (args a (array b c))
   (+ (+ a b) c))
)
```


### Rubysyn: `(call)`

Given a lambda defined by `(lambda)`, or a block defined by `(block)`,
we can call it, passing some arguments.

In the following examples we assume that `$$lam` synvar contains a
lambda, and `$$block` contains a block.

Here are some examples of calling lambdas:

* `(call $$lam <arg>...)`: the most common way;

* `(call $$lam)`: no arguments;

* `(call $$lam <arg>... (kwargs ...))`: positional arguments and keyword arguments, see below;

Positional arguments can contain splat arguments, specified by the `(splat <val>)` clause:

```lisp

(assign arr (array 30 40))
(call $$lam 20 (splat arr))

;; roughly equivalent to:
;; arr = [ 30, 40]
;; foo(20, *arr)

```

Keyword arguments in `(kwargs)` clause are specified similarly to
Rubysyn hash syntax:

```lisp

(call $$lam "hello" (kwargs (:foo . 2) (:bar . true)))

;; roughly equivalent to:
;; foo("hello", foo: 2, bar: true)

```

Splat keyword arguments are provided by a `(splat <val>)` clause:

```lisp

(assign args ((:foo . 2) (:bar . true)))
(call $$lam "hello" (kwargs (splat args)))

;; roughly equivalent to:
;; args = { foo: 2, bar: true }
;; foo("hello", **args)
```

#### Runtime behavior of `(call)`

The behavior of`(call)` is very dynamic.  This may be contrary to your
expectations based on Lisp syntax.

Arguments of `(call)` are evaluated one by one, and assigned to
corresponding arguments of `$$lam`.

Exact sequence would be described separately, for now it's enough to
say that it matches current Ruby semantics.

Here are known sources of dynamic behavior:

* optional arguments can cause evaluation if there is no value provided;

* rest-arguments cause array instantiation;

* `(splat)` for both positional and keyword arguments cause runtime
  behavior;

* too many and too few arguments cause corresponding exceptions;

### Rubysyn: `(return)`

`return` keyword corresponds to the `(return <val?>)` clause.

Return is defined in a very primitive way using Rubysyn primitives:

* `(return val)` is implemented as `(tailcall $$current-return-label val)`;

`$$current-return-label` is internally defined to set the
`$$return-value` synvar:

```lisp
(label $current-return-label $$return-value)
```

`$$current-return-label` is modified by `(call)` for lambdas (but not
for blocks), and by `(ensure)`.  No other clause touches it.  When the
lambda is exited (at the bottom), the previous value of
`$$current-return-label` is restored.

Implicit return is handled in an interesting way.  Basically there is
an implicit return at the Rubysyn level too.

Here is a simple example:

```ruby
def fact(x)
  if x == 1
    return 1
  end

  fact(x - 1) * x
end

t = fact(3)
```

In Rubysyn:

```lisp
(def fact
  (lambda (args x)
    (seq
      (if (== x 1)
        (return 1))
      (* (send :fact (- x 1)) x))))

(var t)
(assign t (send :fact 3))
```

Let's add implicit definitions that are added into `(lambda)` to be
used when it is called by `(call)`:

```lisp
(def fact
  (lambda (args x)
    (seq
      (synvar $$return-value) ;; implicit
      (if (== x 1)
        (return 1))
      (return (* (send :fact (- x 1)) x))) ;; explicit `(return)` added
      (label $$current-return-label $$return-value) ;; implicit, at the very end
  )
)

(var t)
(assign t (send :fact 3))
```

What we see here:

* `(synvar $$return-value)`: an implicit synvar is declared here,
  initialized with `nil`.  It's going to be the value returned by the
  lambda call.

* explicitly added `(return)` at the end.  In principle, we could just
  use `(assign $$return-value (* (send :fact (- x 1) x)))` here,
  because `(tailcall)` right next to the `(label)` could be simplified.

* `(label $$current-return-label $$return-value)`: an implicit
  tailcall label at the very end of `(lambda)`.  If it is used as a
  tailcall target, `$$return-value` is assigned.

`$$return-value` is special because it corresponds to some sort of
slot where the return value would be stored.  More on that in the
"Memory management" section.

Particularly, the return value slot can be optimized away if the
return value is not used.

Return value slots are a general concept that exists for all other
clauses, but in case of `(return)` it needed to be described in more
detail here.

At the top level, `$$current-return-label` is set up in such a way
that it raises `LocalJumpError` exception:

```
3.3.10 :001 > return
(irb):1:in `<main>': unexpected return (LocalJumpError)
```


## Classes, modules and methods

### Rubysyn: `(class)`

Classes are defined or reopened using the following syntax:

```lisp

(class (<Name> . <superclass>) <body>...)

(class <Name> <body>...)

```

`<Name>` is the name of the class, e.g. `Foo`, or `nil` for anonymous classes.

`<superclass>` is the name of the superclass, possibly including `::`.

`<body>` is a sequence of operators.

```lisp
(class Foo)

(class (Bar . Foo))
```

correponds to

```ruby
class Foo

end

class Bar < Foo

end

```

### Rubysyn: `(singleton-class)`

Singleton classes are opened by the following syntax:

```lisp
(singleton-class obj <body>...)
```

You can open the singleton class of many object instances, including
classes themselves.  For some instances such as `1` or `true` this is
not possible.

```lisp
(class C)

(singleton-class C
   ;;; method definitions etc.
)

(assign obj "hello")

(singleton-class obj
   ;;; method definitions etc.
)

```

corresponds to:

```ruby
class C

end

class << C
  # method definitions on class C
end

obj = Foo.new

class << obj
  # method definitions on obj instance
end

```


### Rubysyn: modules

Modules are defined and reopened by the following syntax:

```lisp
(module MyModule <body>...)
```

This corresponds to the usual Ruby:

```ruby
module MyModule
  ...
end
```

You may use fully-qualified module names as usual, such as `Foo::Bar`
and `::Foo`.

### `self`

Ruby `self` is implemented by the standard synvar `$$self`.

`(class)`, `(module)` and `(def)` change the value of `$$self`
correspondingly.  It may be an instance of `Class`, `Module`, or
`Object`, or whatever is possible for `self`.  There is also a special
instance of `$$self` that exists on the top level.

`$$self` cannot be assigned to directly.

### `include`

Ruby `include` keyword corresponds to `(include ModuleName)` clause in
Rubysyn.

### `def`

Methods are defined using the following general syntax:

```lisp
(def <method_name> <lambda>)
```

Method names use exactly the same syntax as Ruby itself, including
weirder operator stuff like `+`, `-@`, `[]` and so on.  Examples:

```lisp
(class C
  (def attr (lambda
    @attr)) ;; instance variables to be discussed

  (def attr= (lambda (args val)
    (instance-assign @attr val)))

  (def -@ (lambda
    "negated"))
)
```

`<lambda>` is an instance of lambda: you can use a `(lambda)` clause
directly, or some variable.  If the value provided is not a lambda,
the syntax error exception is raised.

The method is defined on the so called current receiver.  Current
receiver is stored in the `$$receiver` synvar.  It is assigned by
`(class)`, `(module)`, `(singleton-class)`, and also by the top level.

`$$receiver` cannot be assigned to directly.

`$$receiver` is distinct from `$$self`.  One case that is not
documented clearly could be demonstrated by the top-level definitions:

```ruby

def foo
  1
end

def self.bar
  2
end

```

NB: this is currently handwavy, we hope to explain it precisely and
demonstrate the difference on a clear example.

Here is a simple example of all method variants:

```ruby

class C

  def foo
    "normal method, exists on all instances of class C"
  end

  def self.bar
    "instance method, can be called only by C.bar"
  end

  def C.baz
    "instance method, same as self.bar: `self === C` is true here"
  end
end

s = "hello"
def s.quux
  "singleton method: it exists only on this specific string instance, `another_string.quux` fails"
end

module M
  def grumble
    "class method? terminology unclear"
  end
end

```

Here are the same definitions in Rubysyn:

```lisp
(class C
  ;; note that $$self is now C, and $$receiver is C

  (def foo (lambda "normal method, exists on all instances of class C"))

  (singleton-class $$self
    ;; $$receiver is now a singleton class of C
    (def bar (lambda "instance method, can be called only by `(send (C . bar))`")))

  (singleton-class C
    ;; $$receiver is now also a singleton class of C
    (def baz (lambda "instance method, same as previous: `(=== self C)` is true here")))
)

(var s)
(assign s "hello")
(singleton-class s
  ;; $$receiver is now a singleton class of s
  (def quux (lambda "singleton method: it exists only on this specific string instance, `(send (another_string . quux))` fails")))

(module M
  ;; $$receiver is now M
  (def grumble (lambda "class method? terminology unclear"))
)
```

There seems to be a substantial confusion in terminology around this.
See also the
["Modules / Methods"](https://docs.ruby-lang.org/en/3.4/syntax/modules_and_classes_rdoc.html#label-Methods)
chapter. To be clarified.


### `(send)`

Methods are called using the following general syntax:

```lisp
(send <method_name> <args>...)
```

and

```lisp
(send (<receiver> . <method_name>) <args>...)
```

Method of the superclass is called by:

```lisp
(send (super) <args>...)
```

`<method_name>` is a symbol.  `<receiver>` is any value.

The `<args>` syntax is the same as in `(call)`, described above.


Here are some examples:

```lisp
(send :factorial 20)

(send (File . :new) "t.txt")

(send ($$self . hello) "world" (kwargs (:friendly . true)))

(send (2 . :+) 3)
;;; NB: (+ 2 3) is also possible, see below
```

The corresponding Ruby code:

```ruby
factorial(20)

File.new("t.txt")

self.hello("world", friendly: true)

2 + 3
\# equivalent to 2.+(3)
```

If the receiver is not specified, `$$receiver` is used by default (the
same thing as used for `(def)`).

In runtime, `(send)` first resolves the method, looking at receiver
and its inheritance chain, autoload, etc.  The resolution semantics
matches with Ruby, to be described later.

If the method is successfully resolved to a lambda, `(call)` is used
to pass it the arguments.  The return value becomes the result of
`(send)`.

If a method could not be resolved, `NoMethodError` exception is
raised.

Fun fact: `super` syntax is not described in the official
documentation
[https://docs.ruby-lang.org/en/3.4/syntax/keywords_rdoc.html](https://docs.ruby-lang.org/en/3.4/syntax/keywords_rdoc.html).
At the same time, Ruby's `super` syntax is pretty uncommon because it
does not mention the method name:

```ruby
class C < A
  def foo(x)
    do_something();

    super(x)
  end
end
```

Most other languages use something
akin to `super.method_name`.

### Rubysyn: operators syntax sugar

In the beginning we declared the goal to have a sugar-free syntax.

For readability we introduce a little bit of Rubysyn sugar: operators.

All standard operators in Ruby have corresponding syntax in Rubysyn:

```lisp
(+ 2 3) ;; 5

(! true) ;; false

(- 5) ;; -5

(- 10 2) ;; 8

([] arr 2) ;; equivalent to arr[2] in Ruby
```

And so on.  That syntax strictly checks the arity, and is desugared
into corresponding `(send)`.  Incorrect arity here causes
Rubysyn-level syntactic error.

```lisp
(+ 2 3 5)
;; => Rubysyn syntax error

(send (2 . :+) 3 5)
;; => runtime ArgumentError exception

```

Operator precedence is not needed because it is explicit.

If the code uses `send` method explicitly, it is treated as any other
method:

```ruby
File.send(:new, "README.md")
```

corresponds to

```lisp
(send (File . :send) :new "README.md")
```

#### Variable reference / 0-arity call ambiguity

In Ruby, bare `foo` may famously refer to either a local variable
`foo`, or to a method call with no arguments and with default
receiver.  You can force the method call by adding parens: `foo()`.

Rubysyn needs to handle this case because it is an alternative Ruby
syntax.

In Rubysyn, bare `foo` is always a local variable.  Method call is
always a `(send :foo)`.

To express this particular syntactic ambiguity, we use the `(resolve)`
synmacro.

```lisp
(resolve foo)
```

Note that `foo` is not a symbol, but a terminal token.  If `foo` is
defined as a local variable, `(resolve)` resolves to `foo`, otherwise
to `(send :foo)`.  If neither exists, a corresponding `NameError`
exception is raised.


## Rubysyn: literals

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

### Symbol literals

Symbols use the same syntax as in Ruby: `:foo`.

For interpolations a standard function is used:

````lisp
(string-to-symbol "foo")

;; => :foo

````

### Hash literals

Hash objects use traditional alist syntax:

````lisp
((<key> . <val>) (<key2> . <val2>) ...)

;; empty hash
()

````

corresponds to Ruby syntax

````ruby
{ key => val, key2 => val2, ... }

\# empty hash
{}
````

Modern-style syntax is just sugar:

````ruby
{ foo: bar, baz: 20 }
````

corresponds to

````lisp
((:foo . bar) (:baz . 20))
````
