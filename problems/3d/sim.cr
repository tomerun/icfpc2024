def print(field)
end

record Travel, dt : Int64, y : Int64, x : Int64, v : String | Int64

class Field
  @h : Int32
  @w : Int32
  getter :f, :h, :w

  def initialize(@f : Array(Array(String | Int64)))
    @h = @f.size
    @w = @f[0].size
  end

  def initialize(@h, @w)
    @f = Array.new(h) { Array(String | Int64).new(w, ".") }
  end

  def to_s(io)
    width = @f.max_of { |row| row.max_of { |v| v.to_s.size } }
    @f.each do |row|
      io << row.map { |v| v.to_s.rjust(width) }.join(" ") << "\n"
    end
    io
  end

  def step : Field | Array(Travel) | String | Int64
    nf = Field.new(@f.map { |row| row.dup })

    # consume
    @h.times do |i|
      @w.times do |j|
        case @f[i][j]
        when "<"
          if @f[i][j + 1] != "."
            nf.f[i][j + 1] = "."
          end
        when ">"
          if @f[i][j - 1] != "."
            nf.f[i][j - 1] = "."
          end
        when "^"
          if @f[i + 1][j] != "."
            nf.f[i + 1][j] = "."
          end
        when "v"
          if @f[i - 1][j] != "."
            nf.f[i - 1][j] = "."
          end
        when "+", "-", "*", "/", "%"
          if @f[i - 1][j] != "." && @f[i][j - 1] != "."
            nf.f[i - 1][j] = "."
            nf.f[i][j - 1] = "."
          end
        when "@"
          # no need to check
        when "="
          if @f[i - 1][j] != "." && @f[i][j - 1] != "." && @f[i - 1][j] == @f[i][j - 1]
            nf.f[i - 1][j] = "."
            nf.f[i][j - 1] = "."
          end
        when "#"
          if @f[i - 1][j] != "." && @f[i][j - 1] != "." && @f[i - 1][j] != @f[i][j - 1]
            nf.f[i - 1][j] = "."
            nf.f[i][j - 1] = "."
          end
        end
      end
    end

    # operate
    travels = [] of Travel
    write_cnt = Array.new(@h) { Array.new(@w, 0) }
    result : String | Int64 | Nil = nil

    write = uninitialized Proc(Int32, Int32, String | Int64, Nil)
    write = ->(y : Int32, x : Int32, v : String | Int64) {
      if nf.f[y][x] == "S"
        if result
          raise "submit multiple times: (#{y} #{x}) #{result} #{v}"
        end
        result = v
      end
      nf.f[y][x] = v
      write_cnt[y][x] += 1
    }

    @h.times do |i|
      @w.times do |j|
        case @f[i][j]
        when "<"
          if @f[i][j + 1] != "."
            write.call(i, j - 1, @f[i][j + 1])
          end
        when ">"
          if @f[i][j - 1] != "."
            write.call(i, j + 1, @f[i][j - 1])
          end
        when "^"
          if @f[i + 1][j] != "."
            write.call(i - 1, j, @f[i + 1][j])
          end
        when "v"
          if @f[i - 1][j] != "."
            write.call(i + 1, j, @f[i - 1][j])
          end
        when "+", "-", "*", "/", "%"
          if @f[i - 1][j] != "." && @f[i][j - 1] != "."
            if !@f[i - 1][j].is_a?(Int64) || !@f[i][j - 1].is_a?(Int64)
              raise "invalid args: (#{i} #{j}) #{@f[i][j]} #{@f[i - 1][j]} #{@f[i][j - 1]}"
            end
            case @f[i][j]
            when "+"
              write.call(i + 1, j, @f[i][j - 1].as(Int64) + @f[i - 1][j].as(Int64))
              write.call(i, j + 1, @f[i][j - 1].as(Int64) + @f[i - 1][j].as(Int64))
            when "-"
              write.call(i + 1, j, @f[i][j - 1].as(Int64) - @f[i - 1][j].as(Int64))
              write.call(i, j + 1, @f[i][j - 1].as(Int64) - @f[i - 1][j].as(Int64))
            when "*"
              write.call(i + 1, j, @f[i][j - 1].as(Int64) * @f[i - 1][j].as(Int64))
              write.call(i, j + 1, @f[i][j - 1].as(Int64) * @f[i - 1][j].as(Int64))
            when "/"
              write.call(i + 1, j, @f[i][j - 1].as(Int64).tdiv(@f[i - 1][j].as(Int64)))
              write.call(i, j + 1, @f[i][j - 1].as(Int64).tdiv(@f[i - 1][j].as(Int64)))
            when "%"
              write.call(i + 1, j, @f[i][j - 1].as(Int64).remainder(@f[i - 1][j].as(Int64)))
              write.call(i, j + 1, @f[i][j - 1].as(Int64).remainder(@f[i - 1][j].as(Int64)))
            end
          end
        when "@"
          if @f[i - 1][j] != "." && @f[i][j - 1] != "." && @f[i + 1][j] != "." && @f[i][j + 1] != "."
            if !@f[i][j - 1].is_a?(Int64) || !@f[i + 1][j].is_a?(Int64) || !@f[i][j + 1].is_a?(Int64)
              raise "invalid args: (#{i} #{j}) #{@f[i][j]} #{@f[i - 1][j]} #{@f[i][j - 1]} #{@f[i + 1][j]} #{@f[i][j + 1]}"
            end
            travels << Travel.new(@f[i + 1][j].as(Int64), i - @f[i][j + 1].as(Int64), j - @f[i][j - 1].as(Int64), @f[i - 1][j])
          end
        when "="
          if @f[i - 1][j] != "." && @f[i][j - 1] != "." && @f[i - 1][j] == @f[i][j - 1]
            write.call(i + 1, j, @f[i - 1][j])
            write.call(i, j + 1, @f[i - 1][j])
          end
        when "#"
          if @f[i - 1][j] != "." && @f[i][j - 1] != "." && @f[i - 1][j] != @f[i][j - 1]
            write.call(i + 1, j, @f[i][j - 1])
            write.call(i, j + 1, @f[i - 1][j])
          end
        end
      end
    end
    if write_cnt.flatten.any? { |c| c > 1 }
      puts "overwritten multiple times"
      puts write_cnt.join("\n")
      exit
    end
    if result
      return result.not_nil!
    end
    if !travels.empty?
      if !travels.all? do |t|
           travels[0].dt == t.dt && (travels[0].y != t.y || travels[0].x != t.x || travels[0].v == t.v)
         end
        puts "invalid travel"
        puts travels.join
        exit
      end
      return travels
    end
    return nf
  end
end

def input
  param = read_line.split.map(&.to_i64)
  tf = File.read_lines(ARGV[0]).map { |row| row.split }
  h = tf.size
  w = tf[0].size
  field = Array.new(h) { Array(String | Int64).new(w, ".") }
  h.times do |i|
    w.times do |j|
      field[i][j] = tf[i][j] =~ /^-?\d+$/ ? tf[i][j].to_i64 : tf[i][j]
      if field[i][j] == "A"
        field[i][j] = param[0]
      elsif field[i][j] == "B"
        field[i][j] = param[1]
      end
    end
  end
  return Field.new(field)
end

def main
  fields = [input()]
  puts "h:#{fields[0].h} w:#{fields[0].w}"
  turn = 0
  vt = 1
  while true
    turn += 1
    if turn == 10000
      puts "sim limit exceed"
      break
    end
    puts "t:#{fields.size}"
    puts fields[-1]
    res = fields[-1].step
    case res
    when Field
      fields << res
      vt = {vt, fields.size}.max
    when Array(Travel)
      # vt = {vt, fields.size + 1}.max
      fields.delete_at(-res[0].dt..)
      res.each do |travel|
        puts travel
        fields[-1].f[travel.y][travel.x] = travel.v
      end
    else
      puts "sim finished! t:#{vt} score:#{vt * fields[-1].h * fields[-1].w}"
      puts res
      break
    end
  end
end

main
