RND        = Random.new
TL         = (ENV["TL"]? || 10000).to_i
BEAM_WIDTH = (ENV["BW"]? || 10).to_i
LIMIT_T    = (ENV["LIMIT"]? || 10_000_000).to_i
alias Point = Tuple(Int32, Int32)
DVY = [0, -1, -1, -1, 0, 0, 0, 1, 1, 1]
DVX = [0, -1, 0, 1, -1, 0, 1, -1, 0, 1]
M2I = [
  [5, 6, 4],
  [8, 9, 7],
  [2, 3, 1],
]
TARGETS = [{0, 0}]

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

struct State
  getter :t, :vy, :vx

  def initialize(@t : Int32, @vy : Int32, @vx : Int32)
  end
end

class Solver
  def initialize
    @history = Array(Array(Tuple(Int32, State))).new(TARGETS.size) { [] of Tuple(Int32, State) }
    @history[0] << {0, State.new(0, 0, 0)}
  end

  def solve
    beam = [State.new(0, 0, 0)]
    (TARGETS.size - 1).times do |i|
      cy, cx = TARGETS[i]
      ny, nx = TARGETS[i + 1]
      puts "turn:#{i}"
      puts "(#{cy} #{cx}) -> (#{ny} #{nx})"
      hands = [] of Tuple(Int32, State)
      beam.each_with_index do |state, prev_si|
        ty = min_duration(cy, ny, state.vy)
        tx = min_duration(cx, nx, state.vx)
        ut = {ty, tx, 1}.max
        next if state.t + ut > LIMIT_T
        max_yv = max_velocity(cy, ny, state.vy, ut)
        min_yv = min_velocity(cy, ny, state.vy, ut)
        max_xv = max_velocity(cx, nx, state.vx, ut)
        min_xv = min_velocity(cx, nx, state.vx, ut)
        hands << {prev_si, State.new(state.t + ut, max_yv, max_xv)}
        hands << {prev_si, State.new(state.t + ut, max_yv, min_xv)}
        hands << {prev_si, State.new(state.t + ut, min_yv, max_xv)}
        hands << {prev_si, State.new(state.t + ut, min_yv, min_xv)}
        puts "ty:#{ty} tx:#{tx} vy:#{state.vy} vx:#{state.vx}"
        puts "max_yv:#{max_yv}"
        puts "min_yv:#{min_yv}"
        puts "max_xv:#{max_xv}"
        puts "min_xv:#{min_xv}"
      end
      next_beam = [] of State
      exist_vs = Set(Tuple(Int32, Int32)).new
      hands.sort_by { |_, s| s.t }.each do |prev_si, s|
        next if exist_vs.includes?({s.vy, s.vx})
        exist_vs << {s.vy, s.vx}
        @history[i + 1] << {prev_si, s}
        next_beam << s
        break if next_beam.size == BEAM_WIDTH
      end
      beam = next_beam
    end
    if beam.empty?
      return
    end
    states = [] of State
    si = 0
    (TARGETS.size - 1).downto(0) do |i|
      hist = @history[i][si]
      si = hist[0]
      states << hist[1]
    end
    states.reverse!
    ans = [] of Int32
    (TARGETS.size - 1).times do |i|
      st0 = states[i]
      st1 = states[i + 1]
      yas = recover(TARGETS[i + 1][0] - TARGETS[i][0], st0.vy, st1.vy, st1.t - st0.t)
      xas = recover(TARGETS[i + 1][1] - TARGETS[i][1], st0.vx, st1.vx, st1.t - st0.t)
      yas.size.times { |i| ans << M2I[yas[i]][xas[i]] }
    end
    puts ans.join
  end

  def recover(dist, sv, gv, t)
    puts [dist, sv, gv, t]
    move = sv.to_i64 * t
    acc = Array.new(t, 0)
    if sv < gv
      (gv - sv).times do |i|
        acc[i] = 1
        move += t - i
      end
    elsif sv > gv
      (sv - gv).times do |i|
        acc[i] = -1
        move -= t - i
      end
    end
    lo = 0
    hi = t - 1
    if move < dist
      while acc[lo] == 1
        lo += 1
      end
      while lo < hi && move < dist
        if move + (hi - lo) <= dist
          acc[lo] += 1
          acc[hi] -= 1
          move += hi - lo
          if acc[lo] == 1
            lo += 1
          end
          if acc[hi] == -1
            hi -= 1
          end
        else
          lo += 1
        end
      end
    elsif move > dist
      while acc[lo] == -1
        lo += 1
      end
      while lo < hi && move > dist
        if move - (hi - lo) >= dist
          acc[lo] -= 1
          acc[hi] += 1
          move -= hi - lo
          if acc[lo] == -1
            lo += 1
          end
          if acc[hi] == 1
            hi -= 1
          end
        else
          lo += 1
        end
      end
    end
    assert(move == dist)
    # puts acc
    return acc
  end

  def extra(cp, np, v)
    if cp > np
      v *= -1
    end
    dist = (np - cp).abs.to_i64
    ret = [] of Tuple(Int32, Int32) # {last_v, t}
    if v <= 0 || v.to_i64 * (v - 1) // 2 < dist
      return ret
    end
    dp = Array.new(dist + 1) { [] of Tuple(Int32, Int32) } # {v, t}
    if dist % v == 0
    end
  end

  def max_velocity(cp, np, v, t)
    dist = (np - cp).to_i64
    move = v.to_i64 * t
    acc = Array.new(t, 0)
    if dist < move
      t.times do |i|
        # TODO:いったん上げてから下げる
        if move - (t - i) >= dist
          acc[i] = -1
          move -= t - i
          v -= 1
        end
      end
    else
      (t - 1).downto(0) do |i|
        acc[i] = 1
        v += 1
        move += t - i
        if dist < move
          acc[-(move - dist)] = 0
          v -= 1
          break
        elsif dist == move
          break
        end
      end
    end
    return v # , acc
  end

  def min_velocity(cp, np, v, t)
    dist = (np - cp).to_i64
    move = v.to_i64 * t
    acc = Array.new(t, 0)
    if dist < move
      (t - 1).downto(0) do |i|
        acc[i] = -1
        v -= 1
        move -= t - i
        if dist > move
          acc[-(dist - move)] = 0
          v += 1
          break
        elsif dist == move
          break
        end
      end
    else
      t.times do |i|
        if move + t - i <= dist
          acc[i] = 1
          move += t - i
          v += 1
        end
      end
    end
    return v # , acc
  end

  def min_duration(cp, np, v)
    if cp > np
      v *= -1
    end
    dist = (np - cp).abs.to_i64
    if v > 0 && v.to_i64 * (v - 1) // 2 > dist
      t = v
      m = v.to_i64 * (v + 1) // 2
      nt = ((m - dist) ** 0.5).to_i64
      while m - nt * (nt + 1) // 2 > dist
        nt += 1
      end
      return t + nt.to_i
    else
      t = 0
      if v < 0
        t += -v
        dist += -v.to_i64 * (-v - 1) // 2
        v = 0
      end
      m = v.to_i64 * (v + 1) // 2
      gv = ((dist + m) ** 0.5).to_i64
      while gv * (gv + 1) // 2 - m < dist
        gv += 1
      end
      return gv.to_i - v + t
    end
  end
end

def main
  begin
    while true
      line = read_line.split
      break if line.size < 2
      x, y = line.map(&.to_i)
      TARGETS << {y, x}
    end
  rescue IO::EOFError
  end
  solver = Solver.new
  solver.solve
end

main
