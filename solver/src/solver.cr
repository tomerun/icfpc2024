require "common"
require "http/client"

ENDPOINT = "boundvariable.space"
TOKEN    = ENV["TOKEN"]

class Solver
  def initialize
    @client = HTTP::Client.new(ENDPOINT, tls: true)
  end

  def send(input : String)
    puts input
    header = HTTP::Headers{"Authorization" => "Bearer #{TOKEN}"}
    res = @client.post("/communicate", headers: header, body: input)
    parser = Parser.new(res.body)
    puts res.body
    return parser.parse.to_s
  end
end

def main
  solver = Solver.new
  input = [] of Char
  buf = [] of Char
  in_raw = false
  STDIN.gets_to_end.chomp.each_char do |ch|
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
  output = solver.send("S" + input.join)
  puts output
end

main
