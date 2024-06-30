RND          = Random.new
TL           = (ENV["TL"]? || 10000).to_i
BEAM_WIDTH   = (ENV["BW"]? || 10).to_i
TIME_FORWARD = (ENV["TF"]? || 8).to_i
LIMIT_T      = (ENV["LIMIT"]? || 10_000_000).to_i
alias Point = Tuple(Int32, Int32)
DVY = [0, -1, -1, -1, 0, 0, 0, 1, 1, 1]
DVX = [0, -1, 0, 1, -1, 0, 1, -1, 0, 1]
M2I = [
  [5, 6, 4],
  [8, 9, 7],
  [2, 3, 1],
]
TARGETS    = [{0, 0}]
EXTRA_MEMO = Hash(Tuple(Int64, Int32), Hash(Int32, Set(Int32))).new

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
      th_t = LIMIT_T
      turn_start_time = Time.utc.to_unix_ms
      EXTRA_MEMO.clear
      cy, cx = TARGETS[i]
      ny, nx = TARGETS[i + 1]
      puts "turn:#{i} best_time:#{beam[0].t}"
      # puts "(#{cy} #{cx}) -> (#{ny} #{nx})"
      hands = [] of Tuple(Int32, State)
      beam.each_with_index do |state, prev_si|
        ty = min_duration(cy, ny, state.vy)
        tx = min_duration(cx, nx, state.vx)
        extra_y = extra(cy, ny, state.vy, {ty, th_t - state.t}.min)
        extra_x = extra(cx, nx, state.vx, {tx, th_t - state.t}.min)
        ut = {ty, tx, 1}.max
        # puts "ty:#{ty} tx:#{tx} vy:#{state.vy} vx:#{state.vx}"
        TIME_FORWARD.times do |dt|
          break if state.t + ut + dt > th_t
          max_yv = max_velocity(cy, ny, state.vy, ut + dt)
          min_yv = min_velocity(cy, ny, state.vy, ut + dt)
          max_xv = max_velocity(cx, nx, state.vx, ut + dt)
          min_xv = min_velocity(cx, nx, state.vx, ut + dt)
          min_yv.upto(max_yv) do |yv|
            min_xv.upto(max_xv) do |xv|
              hands << {prev_si, State.new(state.t + ut + dt, yv, xv)}
            end
          end
          # hands << {prev_si, State.new(state.t + ut + dt, max_yv, max_xv)}
          # hands << {prev_si, State.new(state.t + ut + dt, max_yv, min_xv)}
          # hands << {prev_si, State.new(state.t + ut + dt, min_yv, max_xv)}
          # hands << {prev_si, State.new(state.t + ut + dt, min_yv, min_xv)}
        end
        extra_y.each do |et, evs|
          if et >= tx
            max_xv = max_velocity(cx, nx, state.vx, et)
            min_xv = min_velocity(cx, nx, state.vx, et)
            evs.each do |eyv|
              hands << {prev_si, State.new(state.t + et, eyv, max_xv)}
              hands << {prev_si, State.new(state.t + et, eyv, min_xv)}
            end
          elsif extra_x.has_key?(et)
            evs.each do |eyv|
              extra_x[et].each do |exv|
                hands << {prev_si, State.new(state.t + et, eyv, exv)}
              end
            end
          end
        end
        extra_x.each do |et, evs|
          if et >= ty
            max_yv = max_velocity(cy, ny, state.vy, et)
            min_yv = min_velocity(cy, ny, state.vy, et)
            evs.each do |exv|
              hands << {prev_si, State.new(state.t + et, max_yv, exv)}
              hands << {prev_si, State.new(state.t + et, min_yv, exv)}
            end
          end
        end
        # puts "max_yv:#{max_yv}"
        # puts "min_yv:#{min_yv}"
        # puts "max_xv:#{max_xv}"
        # puts "min_xv:#{min_xv}"
        th_t = hands.min_of { |h| h[1].t } + 50
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

  def extra(cp, np, v, limit)
    sign = 1
    if cp > np
      v *= -1
      sign *= -1
    end
    dist = (np - cp).abs.to_i64
    ret = Hash(Int32, Set(Int32)).new { |h, k| h[k] = Set(Int32).new } # {t => [last_v]}
    if v <= 0 || v.to_i64 * (v - 1) // 2 < dist || dist == 0
      return ret
    end
    if EXTRA_MEMO.has_key?({dist, v})
      return EXTRA_MEMO[{dist, v}]
    end
    dp = Array.new(dist + 1) { [] of Tuple(Int32, Int32) } # {v, t}
    dp[dist] << {v, 0}
    dist.downto(0) do |i|
      dp[i].each do |cv, ct|
        if i % cv == 0
          # puts ["add", i, cv, ct]
          nt = ct + i // cv
          ret[nt] << cv * sign if nt < limit
        end
        {1, cv - 1}.max.upto({cv + 1, i}.min) do |nv|
          ni = i - nv
          found = false
          dp[ni].size.times do |j|
            if dp[ni][j][0] == nv && ct + 1 < limit
              dp[ni][j] = {nv, {dp[ni][j][1], ct + 1}.min}
              found = true
              break
            end
          end
          if !found && dp[ni].size < 5
            dp[ni] << {nv, ct + 1}
          end
        end
      end
    end
    # if ret.size > 5
    #   keys = ret.keys.to_a
    #   5.times do |i|
    #     pos = RND.rand(keys.size - i) + i
    #     keys.swap(i, pos)
    #   end
    #   keys[5..].each { |k| ret.delete(k) }
    # end
    # # vs_th = ret.size > 8 ? 2 : 3
    # vs_th = 2
    # ret.values.each do |vs|
    #   if vs.size > vs_th
    #     # 遅くなりすぎないように削る
    #     tvs = vs.to_a.sort
    #     vs.clear
    #     vs << tvs[0] << tvs[-1]
    #     if vs_th == 3
    #       vs << tvs[tvs.size // 2]
    #     end
    #   end
    # end
    EXTRA_MEMO[{dist, v}] = ret
    # puts ["extra", cp, np, v, ret]
    return ret
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
