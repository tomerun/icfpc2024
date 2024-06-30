require "big"
N = 81
puts BigInt.new(read_line.chars.map { |v| v.to_i }.join, 9)

BOARD = Array.new(9) { Array.new(9, -1) }
NG    = Array.new(9) { Array.new(9) { Array.new(9, 0) } }

begin
  while true
    line = read_line.strip
    break if line.empty?
    if line == '!'
      # read_line
      # m = read_line.match(/^var\[(\d+)\]$/).not_nil!
      # v0 = m[1].to_i - 6
      # m = read_line.match(/^var\[(\d+)\]$/).not_nil!
      # v1 = m[1].to_i - 6
      # graph[v0][v1] = graph[v1][v0] = true
    else
      m = read_line.match(/^var\[(\d+)\]$/).not_nil!
      v0 = m[1].to_i - 6
      d = read_line.to_i - 1
      y = v0 // 9
      x = v0 % 9
      BOARD[y][x] = d
      3.times do |yi|
        3.times do |xi|
          ny = y // 3 * 3 + yi
          nx = x // 3 * 3 + xi
          NG[ny][nx][d] += 1
        end
      end
      9.times do |ny|
        NG[ny][x][d] += 1
      end
      9.times do |nx|
        NG[y][nx][d] += 1
      end
    end
  end
rescue IO::EOFError
end
puts dfs(0)

def dfs(pos)
  if pos == N
    return BOARD.flatten.join
  end
  y = pos // 9
  x = pos % 9
  if BOARD[y][x] != -1
    return dfs(pos + 1)
  end
  9.times do |i|
    next if NG[y][x][i] > 0
    BOARD[y][x] = i
    ok = true
    3.times do |yi|
      3.times do |xi|
        ny = y // 3 * 3 + yi
        nx = x // 3 * 3 + xi
        if BOARD[ny][nx] == -1
          NG[ny][nx][i] += 1
          if NG[ny][nx][i] == 1 && NG[ny][nx].all? { |v| v > 0 }
            ok = false
          end
        end
      end
    end
    (y + 1).upto(8) do |ny|
      if BOARD[ny][x] == -1
        NG[ny][x][i] += 1
        if NG[ny][x][i] == 1 && NG[ny][x].all? { |v| v > 0 }
          ok = false
        end
      end
    end
    (x + 1).upto(8) do |nx|
      if BOARD[y][nx] == -1
        NG[y][nx][i] += 1
        if NG[y][nx][i] == 1 && NG[y][nx].all? { |v| v > 0 }
          ok = false
        end
      end
    end
    if ok
      ret = dfs(pos + 1)
      return ret if ret
    end
    3.times do |yi|
      3.times do |xi|
        ny = y // 3 * 3 + yi
        nx = x // 3 * 3 + xi
        if BOARD[ny][nx] == -1
          NG[ny][nx][i] -= 1
        end
      end
    end
    (y + 1).upto(8) do |ny|
      if BOARD[ny][x] == -1
        NG[ny][x][i] -= 1
      end
    end
    (x + 1).upto(8) do |nx|
      if BOARD[y][nx] == -1
        NG[y][nx][i] -= 1
      end
    end
  end
  BOARD[y][x] = -1
  return nil
end
