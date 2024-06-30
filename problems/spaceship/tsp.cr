START_TIME = Time.utc.to_unix_ms
RND        = Random.new
TL         = (ENV["TL"]? || 10000).to_i
IC         = (ENV["IC"]? || 1.0).to_f
FC         = (ENV["FC"]? || 10.0).to_f
alias Point = Tuple(Int32, Int32)
TARGETS = [] of Point

macro debug(msg)
  {% if flag?(:local) %}
    STDERR.puts({{msg}})
  {% end %}
end

macro debugf(format_string, *args)
  {% if flag?(:local) %}
    STDERR.printf({{format_string}}, {{*args}})
  {% end %}
end

def crash(msg, caller_line = __LINE__)
  STDERR.puts "[ERROR] line #{caller_line}: #{msg}"
  exit
end

macro assert(cond, msg = "", caller_line = __LINE__)
  {% if flag?(:local) %}
    if !({{cond}})
      crash({{msg}}, {{caller_line}})
    end
  {% end %}
end

def dist(p0, p1)
  (p0[0] - p1[0]).abs + (p0[1] - p1[1]).abs
end

def accept(diff, cooler)
  return true if diff <= 0
  v = -diff * cooler
  return false if v < -8
  return RND.rand(Int32) < (1 << (31 + v).round.to_i)
  # return RND.rand < Math.exp(v)
end

def main
  begin
    while true
      line = read_line.split
      break if line.size < 2
      x, y = line.map(&.to_i)
      TARGETS << {x, y}
    end
  rescue IO::EOFError
  end
  TARGETS.uniq!
  TARGETS.delete({0, 0})
  TARGETS.unshift({0, 0})
  cur_path = initial_sol()
  turn = 0
  best_path = cur_path.dup
  best_diff = 0
  cur_diff = 0
  cooler = IC
  init_time = Time.utc.to_unix_ms
  while true
    if (turn & 0xFF) == 0
      cur_time = Time.utc.to_unix_ms
      if cur_time > START_TIME + TL
        debug("turn:#{turn}\n")
        break
      end
      ratio = (cur_time - init_time) / (START_TIME + TL - init_time)
      cooler = Math.exp((1.0 - ratio) * Math.log(IC) + ratio * Math.log(FC))
    end
    turn += 1
    p0 = RND.rand(cur_path.size)
    p1 = RND.rand(cur_path.size - 1)
    p1 += 1 if p1 >= p0
    p0, p1 = p1, p0 if p1 < p0
    next if p1 == p0 + 1
    v0 = cur_path[p0]
    v1 = cur_path[p1]
    u0 = cur_path[p0 + 1]
    diff = dist(TARGETS[v0], TARGETS[v1]) - dist(TARGETS[v0], TARGETS[u0])
    if p1 != cur_path.size - 1
      u1 = cur_path[p1 + 1]
      diff += dist(TARGETS[u0], TARGETS[u1]) - dist(TARGETS[v1], TARGETS[u1])
    end
    # debug("diff:#{diff} #{cur_diff}")
    if accept(diff, cooler)
      cur_diff += diff
      cur_path[p0 + 1..p1] = cur_path[p0 + 1..p1].reverse
      if cur_diff < best_diff
        debug("cur_diff:#{cur_diff} at turn #{turn}")
        best_diff = cur_diff
        best_path = cur_path.dup
      end
    end
  end
  best_path[1..].each do |i|
    puts TARGETS[i].join(" ")
  end
end

def initial_sol
  n = TARGETS.size - 1
  used = Array.new(n + 1, false)
  used[0] = true
  cy = 0
  cx = 0
  ret = [0]
  n.times do
    ni = 0
    min_dist = 1 << 29
    1.upto(n) do |i|
      next if used[i]
      dist = (cx - TARGETS[i][0]).abs + (cy - TARGETS[i][1]).abs
      if dist < min_dist
        min_dist = dist
        ni = i
      end
    end
    ret << ni
    used[ni] = true
    cx, cy = TARGETS[ni]
  end
  return ret
end

main
