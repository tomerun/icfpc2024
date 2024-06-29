require "common"
require "http/client"

ENDPOINT = "boundvariable.space"
TOKEN    = ENV["TOKEN"]

class API
  def initialize
    @client = HTTP::Client.new(ENDPOINT, tls: true)
  end

  def send(input : String)
    puts input
    header = HTTP::Headers{"Authorization" => "Bearer #{TOKEN}"}
    res = @client.post("/communicate", headers: header, body: input)
    puts res.body
    parser = Parser.new(res.body)
    return parser.parse
  end
end
