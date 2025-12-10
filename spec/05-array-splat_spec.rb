
=begin

(array <value>...)

Semantics: creates an instance of Array.  Corresponds to simple array literal in Ruby (without splats):

Examples:

[] is (array)

[1, 2, 3] is (array 1 2 3)


(array-splat arr chunk)

Semantics: returns a new instance of Array, appending chunk using splat semantics.

If chunk is nil, does nothing.

If chunk is an instance of Array, appends its elements.

If chunk is an instance of Hash, for each key of the Hash appends a
two-element array containing key and value pair.

Examples:

[1, 2, *foo, 3, 4] is (array-splat (array-splat (array 1 2) foo) (array 3 4))

=end

class BrokenToA
  def to_a
    23
  end
end

describe '(array) and (array-splat)' do
  # Sources:
  # https://docs.ruby-lang.org/en/3.2/syntax/literals_rdoc.html#label-Array+Literals
  # (does not explain splat tho)
  #
  it "array-splat nil" do

    foo = nil

    arr = [1, 2, *foo, 3, 4]
    expect(arr).to eq([1, 2, 3, 4])
  end

  it "array-splat an array" do

    foo = [10, 11]

    arr = [1, 2, *foo, 3, 4]
    expect(arr).to eq([1, 2, 10, 11, 3, 4])
  end

  it "array-splat a hash" do

    foo = { foo: :bar, quux: 23 }

    arr = [1, 2, *foo, 3, 4]
    expect(arr).to eq([1, 2, [:foo, :bar], [:quux, 23], 3, 4])
  end

  it "array-splat a value" do

    foo = 20

    arr = [1, 2, *foo, 3, 4]
    expect(arr).to eq([1, 2, 20, 3, 4])
  end

  it "array-splat a value with incorrect to_a" do
    foo = BrokenToA.new

    expect {
      arr = [1, 2, *foo, 3, 4]
    }.to raise_error TypeError
  end

end

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

describe "def array_splat" do

  it "appends nil" do
    foo = array_splat([1, 2], nil)
    expect(foo).to eq([1, 2])
  end

  it "appends array" do
    foo = array_splat([1, 2], [3, 4])
    expect(foo).to eq([1, 2, 3, 4])
  end

  it "appends hash" do
    foo = array_splat([1, 2], { foo: :bar, baz: 23 })
    expect(foo).to eq([1, 2, [ :foo, :bar], [ :baz, 23] ])
  end

  it "appends any other value" do
    foo = array_splat([1, 2], 10)
    expect(foo).to eq([1, 2, 10])
  end

  it "TypeError when a value has incorrect to_a" do
    foo = BrokenToA.new

    expect {
      array_splat([1, 2,], foo)
    }.to raise_error TypeError
  end

end
