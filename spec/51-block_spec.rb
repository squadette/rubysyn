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

end
