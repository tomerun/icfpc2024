RND        = Random.new
TL         = (ENV["TL"]? || 10000).to_i
BEAM_WIDTH = (ENV["BW"]? || 10).to_i
alias Point = Tuple(Int32, Int32)
DVY = [0, -1, -1, -1, 0, 0, 0, 1, 1, 1]
DVX = [0, -1, 0, 1, -1, 0, 1, -1, 0, 1]
M2I = [
  [5, 6, 4],
  [8, 9, 7],
  [2, 3, 1],
]

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

input = File.read_lines(ARGV[0]).map { |line| line.split.map(&.to_i) }.uniq
targets = Hash(Tuple(Int32, Int32), Int32).new
input.each do |p|
  idx = targets.size
  targets[{p[0], p[1]}] = idx
end
visited = Array.new(targets.size, false)
answer = STDIN.read_line
cy = 0
cx = 0
vy = 0
vx = 0
answer.chars.each do |ch|
  ay = DVY[ch.to_i]
  ax = DVX[ch.to_i]
  vy += ay
  vx += ax
  cy += vy
  cx += vx
  if targets.has_key?({cx, cy})
    visited[targets[{cx, cy}]] = true
  end
end
puts visited.all? ? "ok #{answer.size}" : "ng: #{visited}"
