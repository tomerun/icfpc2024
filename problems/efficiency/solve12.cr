require "big"
f4 = Array.new(1234568, 0i64)
f4[1] = 1
f4[2] = 2
3.upto(f4.size - 1) do |v5|
  f11 = Array.new(v5 + 1, 0i64)
  v13 = v5
  2.upto(v5 - 1) do |v12|
    v13 = f4[v12] > v12 - 1 && v5 % v12 == 0 ? v13 // f4[v12] * (f4[v12] - 1) : v13
  end
  f4[v5] = {v5, v13 + 1}.min
  if v5 % 1000 == 0
    puts "#{v5} #{f4[v5]}"
  end
end
puts f4[1234567]
