RND = Random.new
M2I = [
  [5, 6, 4],
  [8, 9, 7],
  [2, 3, 1],
]
INF = 1 << 28

targets = File.read_lines(ARGV[0]).map { |line| line.split.map(&.to_i) }.uniq
cx = targets[0][0]
cy = targets[0][1]
iax, vx = initial_move(13, 24)
iay, vy = initial_move(17, 23)
ans = Array.new(iax.size) { |i| M2I[iay[i]][iax[i]] }
(targets.size - 1).times do |i|
  dx = targets[i + 1][0] - targets[i][0]
  dy = targets[i + 1][1] - targets[i][1]
  ax = (dx - vx).sign
  ay = (dy - vy).sign
  vx += ax
  vy += ay
  cx += vx
  cy += vy
  if cx != targets[i + 1][0] || cy != targets[i + 1][1]
    raise "#{i} #{cx} #{cy} #{targets[i + 1]}"
  end
  ans << M2I[ay][ax]
end
puts ans.join

def accept(diff, cooler)
  return true if diff <= 0
  v = -diff * cooler
  return false if v < -8
  return RND.rand(Int32) < (1 << (31 + v).round.to_i)
  # return RND.rand < Math.exp(v)
end

def initial_move(gv, gp)
  max_v = 40
  max_d = 250
  dp = Array.new(42) do
    Array.new(max_v * 2 + 1) do
      Array.new(max_d * 2 + 1) { {INF, INF} }
    end
  end
  dp[0][0][0] = {0, 0}
  (dp.size - 1).times do |i|
    (-max_v).upto(max_v) do |cv|
      (-max_d).upto(max_d) do |cd|
        next if dp[i][cv][cd] == {INF, INF}
        -1.upto(1) do |dv|
          nv = cv + dv
          nd = cd + (dp.size - 1 - i) * dv
          if -max_v <= nv <= max_v && -max_d <= nd <= max_d && dp[i + 1][nv][nd] == {INF, INF}
            dp[i + 1][nv][nd] = {cv, cd}
            if i == dp.size - 2 && nd == gp
              puts ["set", nv, cv, cd]
            end
          end
        end
      end
    end
  end
  last_v = -1
  acc = [] of Int32
  (gv - 1).upto(gv + 1) do |lv|
    next if dp[-1][lv][gp] == {INF, INF}
    last_v = lv
    cv = lv
    cp = gp
    (dp.size - 1).downto(1) do |i|
      puts [i, cv, cp]
      pv, pd = dp[i][cv][cp]
      if pv == INF
        puts dp[i][cv].join("\n")
      end
      acc << cv - pv
      cv = pv
      cp = pd
    end
    break
  end
  return acc.reverse, last_v
  # if dp[-1][gv - 1][gp] != {INF, INF} || dp[-1][gv][gp] != {INF, INF} || dp[-1][gv + 1][gp] != {INF, INF}
  #   puts t
  # end

  # acc = Array.new(38, 0)
  # sum = 0
  # lv = 0
  # 10.times do |i|
  #   acc[i] = -1
  #   sum -= acc.size - i
  #   lv -= 1
  # end
  # (acc.size - 20).upto(acc.size - 1) do |i|
  #   acc[i] = 1
  #   sum += acc.size - i
  #   lv += 1
  # end
  # cur_val = (sum - gp).abs + {(lv - gv).abs - 1, 0}.max
  # cooler = 0.5
  # turn = 0i64
  # while true
  #   turn += 1
  #   if (turn & 0x3FFFFF) == 0
  #     cooler *= 1.1
  #     if cooler > 10
  #       cooler = 0.5
  #     end
  #     puts("turn:#{turn} cur_val:#{cur_val} cooler:#{cooler}")
  #   end
  #   pos = RND.rand(acc.size)
  #   change = acc[pos] == 0 ? RND.rand(2) * 2 - 1 : -acc[pos]
  #   new_sum = sum + (acc.size - pos) * change
  #   new_lv = lv + change
  #   new_val = (new_sum - gp).abs + {(new_lv - gv).abs - 1, 0}.max
  #   if accept(new_val - cur_val, cooler)
  #     acc[pos] += change
  #     sum = new_sum
  #     lv = new_lv
  #     cur_val = new_val
  #     if cur_val == 0
  #       puts "turn:#{turn}"
  #       break
  #     end
  #   end
  # end
  # return acc, lv
end
