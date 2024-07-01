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
  multiline = false
  parser = OptionParser.new do |parser|
    parser.on("-r", "raw") { raw = true }
    parser.on("-m", "multiline") { multiline = true }
  end

  parser.parse

  api = API.new
  begin
    while true
      input = [] of Char
      buf = [] of Char
      in_raw = false
      line = multiline ? STDIN.gets_to_end : STDIN.read_line
      if raw
        body = line.strip
      else
        in_escape = false
        line.each_char do |ch|
          if ch.ord < 128
            if in_raw
              input << ch
            elsif !in_escape && ch == '\\'
              in_escape = true
            elsif in_escape && ch == 'n'
              buf << '\n'
              in_escape = false
            else
              buf << ch
              in_escape = false
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
      break if multiline
    end
  rescue IO::EOFError
  end
end

main
