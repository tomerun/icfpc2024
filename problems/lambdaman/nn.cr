RND    = Random.new
DY     = [1, 0, -1, 0]
DX     = [0, 1, 0, -1]
TL     = (ENV["TL"]? || 10000).to_i
CH_CNT = (ENV["CHC"]? || 2).to_i
field = STDIN.gets_to_end.strip.split("\n").map { |line| line.chars }
h = field.size
w = field[0].size
cy = -1
cx = -1
h.times do |y|
  w.times do |x|
    if field[y][x] == 'L'
      cy = y
      cx = x
    end
  end
end
priority = Array.new(h) { Array.new(w) { [0, 1, 2, 3] } }
cross_pos = [] of Tuple(Int32, Int32)
h.times do |y|
  w.times do |x|
    if 4.times.count do |i|
         ny = y + DY[i]
         nx = x + DX[i]
         0 <= ny < h && 0 <= nx < w && field[ny][nx] != '#'
       end > 1
    end
    cross_pos << {y, x}
  end
end
best = solve(field, priority, cy, cx)
start_time = Time.utc.to_unix_ms
turn = 0
while true
  if Time.utc.to_unix_ms - start_time > TL
    STDERR.puts "turn:#{turn}"
    break
  end
  turn += 1
  ch_pos = [] of Tuple(Int32, Int32, Int32)
  (RND.rand(CH_CNT) + 1).times do |i|
    idx = RND.rand(cross_pos.size)
    d0 = RND.rand(4)
    d1 = RND.rand(3)
    d1 += 1 if d1 >= d0
    ch_pos << {idx, d0, d1}
    priority[cross_pos[idx][0]][cross_pos[idx][1]].swap(d0, d1)
  end
  cur = solve(field, priority, cy, cx)
  if cur.size <= best.size
    if cur.size < best.size
      STDERR.puts "best #{best.size} at turn #{turn}"
    end
    best = cur
  else
    ch_pos.reverse_each do |idx, d0, d1|
      priority[cross_pos[idx][0]][cross_pos[idx][1]].swap(d0, d1)
    end
  end
end
puts best.map { |dir| "DRUL"[dir] }.join

def solve(field, priority, cy, cx)
  h = field.size
  w = field[0].size
  visited = Array.new(h) { Array.new(w, false) }
  visited[cy][cx] = true
  unvis_cnt = field.sum { |row| row.count('.') }
  prev = Array.new(h) { Array.new(w, -1) }
  ans = [] of Int32
  while unvis_cnt > 0
    bfs = Array.new(h) { Array.new(w, false) }
    bfs[cy][cx] = true
    q = [{cy, cx}]
    qi = 0
    while true
      y, x = q[qi]
      break if !visited[y][x]
      qi += 1
      4.times do |i|
        dir = priority[y][x][i]
        ny = y + DY[dir]
        nx = x + DX[dir]
        next if ny < 0 || h <= ny || nx < 0 || w <= nx
        next if field[ny][nx] == '#'
        next if bfs[ny][nx]
        bfs[ny][nx] = true
        prev[ny][nx] = dir
        q << {ny, nx}
      end
    end
    y, x = q[qi]
    visited[y][x] = true
    tmp_path = [] of Int32
    while y != cy || x != cx
      dir = prev[y][x]
      tmp_path << dir
      y -= DY[dir]
      x -= DX[dir]
    end
    ans += tmp_path.reverse
    cy, cx = q[qi]
    unvis_cnt -= 1
  end
  return ans
end
