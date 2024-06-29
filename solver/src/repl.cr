require "api"
require "common"

def get(api, input)
  prog = api.send(input)
  prog.print(STDOUT, 0)
  while !prog.is_a?(PrimitiveT)
    puts "----eval----"
    ctx = Ctx.new
    prog = prog.eval(ctx)
    prog.print(STDOUT, 0)
  end
  puts "----finish eval----"
  return prog.to_s
end

def main
  api = API.new
  while true
    input = [] of Char
    buf = [] of Char
    in_raw = false
    STDIN.read_line.each_char do |ch|
      if ch.ord < 128
        if in_raw
          input << ch
        else
          buf << ch
        end
      else
        in_raw = !in_raw
        if !buf.empty?
          input += StringT.convert(buf)
          buf.clear
        end
      end
    end
    if !buf.empty?
      input += StringT.convert(buf)
      buf.clear
    end
    output = get(api, "S" + input.join)
    puts output
  end
end

main
