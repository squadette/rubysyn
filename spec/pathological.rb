def a
  puts "method `a' called"

  99
end

[1, 2, 3, 4].each do |i|
  if i % 2 == 0
    puts "a(#{i}) = #{a}"
  else
    a = a.nil? ? 1 : a + 1
    puts "a(#{i}) = #{a}"
  end
end
