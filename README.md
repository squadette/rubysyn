# Rubysyn: clarifying Ruby's syntax and semantics

**[WIP, 2025-10-02]** This is an experiment in clarifying some aspects
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

#### Default implementations of `#to_a`.

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

## Desugaring constructing array splat

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

## [] is also a sugar

Note that `[]` is itself a sugar for `Array#[]` method:

```ruby
Array.[](2, 3, 4)
# [2, 3, ]
```

So it's possible that constructing array splat actually stems from
function argument processing.

However, for now we consider array literal suffix an independent
syntactical construct.

## Rubysyn: `(array)`

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

## Rubysyn: `(array-splat)`

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
