require "common"

def main
  parser = Parser.new(STDIN.read_line)
  prog = parser.parse
  puts prog.eval
end

main
