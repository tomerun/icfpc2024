M2I = [
  [5, 6, 4],
  [8, 9, 7],
  [2, 3, 1],
]

targets = [[0, 0]] + File.read_lines(ARGV[0]).map { |line| line.split.map(&.to_i) }.uniq
vx = 0
vy = 0
cx = 0
cy = 0
ans = [] of Int32
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
