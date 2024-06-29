require "option_parser"
require "api"
require "common"

def get(api, input)
  prog = api.send(input)
  vars_idx = VarsIdx.new
  prog.rename_vars(vars_idx)
  prog.print(STDOUT, 0)
  while !prog.is_a?(PrimitiveT)
    puts "----eval----"
    ctx = Ctx.new
    prog = prog.eval(ctx)
    prog.print(STDOUT, 0)
  end
  puts "----finish eval----"
  return prog
end

def main
  raw = false
  parser = OptionParser.new do |parser|
    parser.on("-r", "raw") { raw = true }
  end

  parser.parse

  api = API.new
  begin
    while true
      input = [] of Char
      buf = [] of Char
      in_raw = false
      line = STDIN.read_line
      if raw
        body = line.strip
      else
        line.each_char do |ch|
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
        body = "S" + input.join
      end
      output = get(api, body)
      case output
      when StringT
        puts output.s
      when IntegerT
        puts output.v
      when TrueT
        puts true
      when FalseT
        puts false
      end
    end
  rescue IO::EOFError
  end
end

main
