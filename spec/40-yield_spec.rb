describe ".each" do

  # NB: no .each is actually used here, this is strictly yield + next/break behaviour

  def only_once(x)
    yield x
  end

  it "yield returns result of block" do
    t = only_once(3) do |x|
      10
    end
    expect(t).to eq(10)
  end

  it "break returns its argument" do
    t = only_once(3) do |x|
      break 20
    end
    expect(t).to eq(20)
  end

  def only_once_return(x, y)
    yield x

    raise "his never happens?"

    return y
  end

  it "break skips the entire yielding function" do
    t = only_once_return(3, 30) do |x|
      break 20
    end
    expect(t).to eq(20)
  end

  def only_once_block_call(x, y, &block)
    block.call(x)

    raise "this never happens?"

    return y
  end

  it "block.call is yield" do
    t = only_once_block_call(3, 30) do |x|
      break 20
    end
    expect(t).to eq(20)
  end

  def only_once_ensure(x, y, &block)
    begin
      yield x
    ensure

    end

    return y
  end

  it "ensure wraps break, but the entire function still returns" do
    t = only_once_ensure(3, 30) do |x|
      break 20
    end
    expect(t).to eq(20)
  end

  def only_once_ensure_return(x, y, &block)
    begin
      yield x
    ensure
      return 23
    end

    return y
  end

  it "break can be caught by ensure, and then return" do
    t = only_once_ensure_return(3, 30) do |x|
      break 20
    end
    expect(t).to eq(23)
  end

  it "next in block is like return from block" do
    t = only_once(3) do |x|
      next 15

      25
    end

    expect(t).to eq(15)
  end

  it "return in block is a syntax error" do
    expect {
      t2 = only_once(3) do |x|
        return 15

        25
      end
    }.to raise_error LocalJumpError
  end

  it "redo in block runs the block again" do
    counter = 0
    t = only_once(3) do |x|
      counter += 1
      redo if counter < 3

      counter
    end
    expect(t).to eq(3)
  end
end
