require "common"

def main
  parser = Parser.new(STDIN.read_line)
  prog = parser.parse
  vars_idx = VarsIdx.new
  prog.rename_vars(vars_idx)
  puts vars_idx.idx
  prog.print(STDOUT, 0)

  while true
    break if prog.is_a?(PrimitiveT)
    puts "-------------------------------"
    ctx = Ctx.new
    prog = prog.eval(ctx)
    prog.print(STDOUT, 0)
  end
end

main
