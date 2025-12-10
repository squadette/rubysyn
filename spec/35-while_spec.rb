describe 'while' do

  it "assignments in body" do
    while false
      a = 2
    end

    expect(a).to eq(nil)
  end

  it "return nil" do
    a = while false
          10
        end

    expect(a).to eq(nil)
  end

  it "break returns value" do
    a = while true
          break 10
        end

    expect(a).to eq(10)
  end

  it "postfix while: assignment" do
    begin
      expect{ a }.to raise_error NameError
    end while a = false

    expect(a).to eq(false)
  end

  it "postfix while: assignment in condition" do
    begin
      break
    end while a = 20

    expect(a).to eq(nil)
  end
end
