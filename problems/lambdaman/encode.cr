require "big"

v = BigInt.new(0)
line = read_line.chars
if 0.step(to: line.size - 1, by: 2).all? { |i| line[i] == line[i + 1] }
  STDERR.puts "paired"
  0.step(to: line.size - 1, by: 2) do |i|
    dir = line[i]
    v *= 4
    v += "LRUD".index(dir).not_nil!
  end
else
  line.each do |dir|
    v *= 4
    v += "LRUD".index(dir).not_nil!
  end
end
puts v
