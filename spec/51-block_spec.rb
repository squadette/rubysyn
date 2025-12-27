describe "block" do

  def get_block(&block)
    block
  end

  it "return after return" do
    b = get_block do
      return 23
    end

    expect { b.call }.to raise_error LocalJumpError
  end

  it "break after return" do
    b = get_block do
      break 23
    end

    expect { b.call }.to raise_error LocalJumpError
  end

  it "block return in lambda" do

    l = ->(x, &block) do
      block.call
      x
    end

    # when a block returns, and it's not in a lambda/method, we get an
    # exception
    expect do
      l.call 3 do
        return 23
      end
    end.to raise_error LocalJumpError

    # wrap this in lambda, and the entire lambda returns
    l2 = ->() do
      val = l.call 3 do
        return 23
      end

      val
    end

    expect(l2.call).to eq(23)

  end

end
