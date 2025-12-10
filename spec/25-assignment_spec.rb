
=begin

(assign-local-one var <value>)

Semantics:

* if local variable `var` does not exist in current environment,
  create it and set it to nil;

* evaluate <value> in the updated environment, and assign it to `var`;

* returns <value> as the result;

Note that there is no auto-Array sugar here.

=end

describe '(assign-local-one)' do
  # source https://docs.ruby-lang.org/en/3.2/syntax/assignment_rdoc.html
  it "assigns scalar value" do

    # (assign-local-var a 1)
    a = 1
    expect(a).to eq(1)
  end

  it "assigns array value using sugar" do
    # NB: no sugar
    # (assign-local-var a (make-array 1 2 3))
    a = 1, 2, 3
    expect(a).to eq([1, 2, 3])
  end

  it "assigns array value, no sugar" do
    # (assign-local-var a (make-array 1 2 3))
    a = [1, 2, 3]
    expect(a).to eq([1, 2, 3])
  end

  it "splat array is subject to sugar" do
    # TODO: what does splat mean?
    # (assign-local-var a (make-array 1 2 3))
    a = *[1, 2, 3]
    expect(a).to eq([1, 2, 3])
  end

  it "single-element array can be splatted too" do
    a = *[3]
    expect(a).to eq([3])
  end

  it "splat empty array is []" do
    # TODO: what does splat mean?
    # (assign-local-var a (make-array))
    a = *[]
    expect(a).to eq([])
  end

  it "assigns variable to itself" do
    # (assign-local-var a a)
    a = a
    expect(a).to eq(nil)
  end

  it "assigns function of itself" do
    # TODO:
    # (assign-local-var a ...)
    a = a.inspect
    expect(a).to eq("nil")
  end

  it "fails on unassigned variable" do
    # (assign-local-var a b)
    expect{ a = b }.to raise_error NameError
  end

  it "splat of a single value creates array" do
    a = *2
    expect(a).to eq([2])
  end

  it "splat of several values does nothing" do
    a = *1, 2, 3
    expect(a).to eq([1, 2, 3])
  end

  it "splat position does not matter" do
    a = 1, *2, 3
    expect(a).to eq([1, 2, 3])

    a = 1, 2, *3
    expect(a).to eq([1, 2, 3])
  end

  it "splat in single-element array is still ignored" do
    a = [*3]
    expect(a).to eq([3])
  end

  it "splat without sugar works the same way" do
    a = [*1, 2, 3]
    expect(a).to eq([1, 2, 3])

    a = [1, *2, 3]
    expect(a).to eq([1, 2, 3])

    a = [1, 2, *3]
    expect(a).to eq([1, 2, 3])
  end

  it "array can be a member of the list" do
    a = 1, 2, [3]
    expect(a).to eq([1, 2, [3]])
  end

  it "array can be splatted here" do
    a = 1, 2, *[3]
    expect(a).to eq([1, 2, 3])
  end

end
