# Rubysyn: clarifying Ruby's syntax and semantics

**[WIP, 2025-08-31]** This is an experiment in clarifying some aspects
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
  - [Rubysyn: `(array)`](#rubysyn-array)
  - [Rubysyn: `(array-splat)`](#rubysyn-array-splat)

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

* if `foo` is `nil`, `*foo` is removed entirely:

```ruby
foo = nil
[1, 2, *foo, 3]

# [1, 2, 3]
```

* if `foo` is an array, `*foo` is replaced with its elements:

```ruby
foo = [10, 11]
[1, 2, *foo, 3]

# [1, 2, 10, 11, 3]

```

* if `foo` is a hash, `*foo` is replaced by a list of two-element
arrays, one for each hash key:

```ruby
foo = { foo: :bar, quux: 23 }
[1, 2, *foo, 3]

# [1, 2, [ :foo, :bar ], [ :quux, 23 ], 3]

```

* finally, for all other values `*foo` is replaced by the value of
`foo`:

```ruby
foo = "hello"
[1, 2, *foo, 3]

# [1, 2, "hello", 3]

```

### Constructing array splat syntax is underdocumented

For some reason, this is not explained in standard Ruby documentation:

* [Creating Arrays](https://docs.ruby-lang.org/en/3.4/Array.html#class-Array-label-Creating+Arrays);

* [Array Literals](https://docs.ruby-lang.org/en/3.4/syntax/literals_rdoc.html#label-Array+Literals);

This syntax is used in the
[Implicit Array Assignment](https://docs.ruby-lang.org/en/3.4/syntax/assignment_rdoc.html#label-Implicit+Array+Assignment)
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
  case chunk
  when nil
    return arr
  when Array
    return arr.concat(chunk)
  when Hash
    return arr.concat(chunk.keys.map { [ _1, chunk[_1] ] })
  else
    return arr.append(chunk)
  end
end
```

Note that the semantics of this function is not specified in the
standard documentation also, I've gathered it from random sources.
Particularly, I cannot even find a function that would be similar to
`array_splat`.

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

