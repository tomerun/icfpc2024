require "big"
require "common"

def parse(tokens, pos)
  token = tokens[pos]
  # puts "pos:#{pos} token:#{token}"
  pos += 1
  case token
  when "apply"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return ApplyT.new(t0, t1), pos
  when /^concat\[(\d+)\]$/
    cnt = $1.to_i64
    terms = [] of Term
    cnt.times do
      t, pos = parse(tokens, pos)
      terms << t
    end
    while terms.size > 1
      t1 = terms.pop
      t0 = terms.pop
      terms << ConcatT.new(t0, t1)
    end
    return terms[0], pos
  when /^L\[(\d+)\]$/
    vi = $1.to_i64
    t0, pos = parse(tokens, pos)
    return LambdaT.new(vi, t0), pos
  when /^var\[(\d+)\]$/
    vi = $1.to_i64
    return VarT.new(vi), pos
  when "true"
    return TrueT.new, pos
  when "false"
    return FalseT.new, pos
  when /^(\d+)$/
    return IntegerT.new(BigInt.new($1)), pos
  when /^"(.+)"$/m
    return StringT.new($1.gsub("\\n") { "\n" }, true), pos
  when "~"
    t0, pos = parse(tokens, pos)
    return NegT.new(t0), pos
  when "!"
    t0, os = parse(tokens, pos)
    return NotT.new(t0), pos
  when "#"
    t0, pos = parse(tokens, pos)
    return S2IT.new(t0), pos
  when "$"
    t0, pos = parse(tokens, pos)
    return I2ST.new(t0), pos
  when "+"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return AddT.new(t0, t1), pos
  when "-"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return SubT.new(t0, t1), pos
  when "*"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return MulT.new(t0, t1), pos
  when "/"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return DivT.new(t0, t1), pos
  when "%"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return ModT.new(t0, t1), pos
  when "<"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return LessT.new(t0, t1), pos
  when ">"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return GreatT.new(t0, t1), pos
  when "="
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return EqT.new(t0, t1), pos
  when "|"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return OrT.new(t0, t1), pos
  when "&"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return AndT.new(t0, t1), pos
  when "."
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return ConcatT.new(t0, t1), pos
  when "T"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return TakeT.new(t0, t1), pos
  when "D"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    return DropT.new(t0, t1), pos
  when "if"
    t0, pos = parse(tokens, pos)
    t1, pos = parse(tokens, pos)
    t2, pos = parse(tokens, pos)
    return IfT.new(t0, t1, t2), pos
  else
    raise "invalid token #{tokens[pos]}"
  end
end

def tokenize(s)
  tokens = [] of String
  buf = [] of Char
  pos = 0
  in_quot = false
  while pos < s.size
    char = s[pos]
    pos += 1
    if in_quot
      buf << char
      if char == '"'
        in_quot = false
        tokens << buf.join
        buf.clear
      end
    else
      case char
      when '"'
        in_quot = true
        buf << char
      when ' ', '\n', '\t'
        tokens << buf.join if !buf.empty?
        buf.clear
      else
        buf << char
      end
    end
  end
  if !buf.empty?
    tokens << buf.join
  end
  tokens
end

def main
  input = tokenize(STDIN.gets_to_end.strip)
  puts "input size:#{input.size}"
  prog, pos = parse(input, 0)
  assert(pos == input.size)
  puts prog
  # prog.print(STDOUT, 0)
end

main
