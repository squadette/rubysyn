describe "lambda" do

  it "no arguments" do
    l = ->() do
      "foo"
    end

    expect(l.call()).to eq("foo")
  end

  it "not enough arguments" do

    l = ->(x, mode = 23) do
      return "#{x} #{mode}"
    end

    expect { l.call() }.to raise_error ArgumentError
  end

  it "too many arguments" do

    l = ->(x, mode = 23) do
      return "#{x} #{mode}"
    end

    expect { l.call(10, 20, 30) }.to raise_error ArgumentError
  end

  it "default arguments" do

    l = ->(x, mode = 23) do
      return "#{x} #{mode}"
    end

    expect(l.call(10)).to eq("10 23")
  end

  it "break in lambda" do
    l = ->(x, mode = 23) do
      break "#{x} #{mode}"

      a = 20
    end

    expect(l.call(10)).to eq("10 23")
  end

  it "bare break in lambda" do
    l = ->(x, mode = 23) do
      break

      a = 20
    end

    expect(l.call(10)).to eq(nil)
  end

  it "keyword args in lambda" do
    l = ->(x, mode: 23) do
      return "#{x} #{mode}"
    end

    expect(l.call(10, mode: 23)).to eq("10 23")
  end

  it "default keyword args in lambda" do
    l = ->(x, mode: 23) do
      return "#{x} #{mode}"
    end

    expect(l.call(10)).to eq("10 23")
  end

  it "keyword args / splat in lambda" do
    l = ->(x:, y:) do
      return "#{x} #{y}"
    end

    args = { x: 10, y: 20 }
    expect(l.call(**args)).to eq("10 20")
  end

  it "splat argument in lambda" do
    l = ->(x, *y) do
      return "#{x} #{y}"
    end

    expect(l.call(1, 2, 3)).to eq("1 [2, 3]")
  end

  it "no it in lambda" do
    l = Object.new.instance_eval do
      ->(x) do
        return "#{it}"
      end
    end

    expect { l.call(10) }.to raise_error NameError
  end

  it "previous args in default values in lambda" do
    l = ->(x, y = x + 3) do
      return "#{x} #{y}"
    end

    expect(l.call(10)).to eq("10 13")
  end

  it "all possible args + kwargs" do
    l = ->(a, b = 20, *c, d:, e: 42, **f) do
      return [a, b, c, d, e, f]
    end

    expect(l.call(10, 15, 20, 25, d: "x", e: 74, g: 100, h: 200)).to eq([10, 15, [20, 25], "x", 74, {g: 100, h: 200}])
  end

  it "keywords but no keywords in lambda" do
    l = ->(**nil) do

    end

    args = {}
    expect(l.call(*args)).to eq(nil)

    args = {foo: 20}
    expect { l.call(*args) }.to raise_error ArgumentError
  end

  it "splat call" do

    l = ->(x, y, z) do
      return "#{x} #{y} #{z}"
    end

    args = [20, 30]
    expect(l.call(10, *args)).to eq("10 20 30")
  end


end
