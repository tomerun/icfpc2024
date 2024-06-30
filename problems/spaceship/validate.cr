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

targets = File.read_lines(ARGV[0]).map { |line| line.split.map(&.to_i) }
answer = STDIN.read_line
pi = 0
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
  if targets[pi][0] == cx && targets[pi][1] == cy
    pi += 1
  end
end
puts pi == targets.size ? "ok #{answer.size}" : "ng: #{pi}"
