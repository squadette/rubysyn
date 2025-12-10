describe 'if' do
  it "nested if assignments" do

    if true

      expect{ b }.to raise_error NameError

    else
      # this branch is never taken, but all assignments declared here
      # are valid after the end of `if` (recursively).
      a = 23
      if false
        b = 20
      else
        c = 10
      end

      puts "hello" if e = 30

      quux(f = 40)

      { foo: (g = 20) }
    end

    expect(a).to eq(nil)
    expect(b).to eq(nil)
    expect(c).to eq(nil)
    expect{ d }.to raise_error NameError
    expect(e).to eq(nil)
    expect(f).to eq(nil)
    expect(g).to eq(nil)
  end

  it "begin / end" do
    begin
      a = 23
    rescue Foo::Bar
      b = 20

      if true
        c = 10
      end
    end

    expect(a).to eq(23)
    expect(b).to eq(nil)
    expect(c).to eq(nil)
  end

  it "while" do
    while false
      a = 10

      if false
        b = 10
      end

      self.foo do
        c = 30
      end
    end

    expect(a).to eq(nil)
    expect(b).to eq(nil)
    expect{ c }.to raise_error NameError
  end
end
