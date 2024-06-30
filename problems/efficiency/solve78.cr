record Cond, idx : Int32, neg : Bool

CONDS = [] of Array(Cond)
begin
  while true
    line = read_line.strip
    break if line.empty?
    if line[0] != '|'
      m = line.match(/^(!)?var\[(\d+)\]$/).not_nil!
      CONDS << [Cond.new(idx: m[2].to_i - 6, neg: !m[1]?.nil?)]
    else
      CONDS << Array.new(line.size + 1) do
        line = read_line
        m = line.match(/^(!)?var\[(\d+)\]$/).not_nil!
        Cond.new(idx: m[2].to_i - 6, neg: !m[1]?.nil?)
      end
    end
  end
rescue IO::EOFError
end

puts CONDS.join("\n")
max_var = CONDS.flatten.max_of { |c| c.idx }
i2v = Array.new(max_var + 1) { [] of Int32 }
CONDS.size.times do |i|
  CONDS[i].each do |c|
    i2v[c.idx] << i
  end
end
puts dfs(Array.new(max_var + 1, 0), max_var, i2v)

def dfs(bits, pos, i2v)
  if pos == -1
    puts(CONDS.map do |conds|
      conds.any? do |cond|
        bits[cond.idx] == (cond.neg ? 0 : 1)
      end
    end)
    puts bits
    return bits.reverse.join.to_i64(2)
  end
  2.times do |i|
    bits[pos] = i
    if i2v[pos].all? do |ci|
         CONDS[ci].any? do |cond|
           if cond.idx >= pos
             bits[cond.idx] == (cond.neg ? 0 : 1)
           else
             true
           end
         end
       end
      ret = dfs(bits, pos - 1, i2v)
      return ret if ret && ret > 0
    end
  end
  return nil
end
