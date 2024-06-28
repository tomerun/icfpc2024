STR_TBL     = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`|~ \n"
STR_TBL_REV = Array.new(STR_TBL.size) { |i| v = STR_TBL.index('!' + i); v ? '!' + v : ' ' }

class TrueT
  def eval
    self
  end

  def to_s(io)
    io << true
  end
end

class FalseT
  def eval
    self
  end

  def to_s(io)
    io << false
  end
end

class IntegerT
  getter :v

  def initialize(s : String)
    @v = 0i64
    s.each_char do |ch|
      @v *= 94
      @v += ch - '!'
    end
  end

  def initialize(@v : Int64)
  end

  def eval
    self
  end

  def to_s(io)
    io << @v
  end
end

class StringT
  getter :s

  def initialize(s : String, raw = false)
    if raw
      @s = s
    else
      @s = s.chars.map { |ch| STR_TBL[ch - '!'] }.join
    end
  end

  def self.convert(cs : Array(Char))
    cs.map { |ch| ch == ' ' ? '}' : ch == '\n' ? '~' : STR_TBL_REV[ch - '!'] }
  end

  def self.convert(s : String)
    self.convert(s.chars).join
  end

  def eval
    self
  end

  def to_s(io)
    io << @s
  end
end

class NegT
  def initialize(@t : Term)
  end

  def eval
    IntegerT.new(-@t.eval.as(IntegerT).v)
  end
end

class NotT
  def initialize(@t : Term)
  end

  def eval
    v = @t.eval
    if v.is_a?(TrueT)
      FalseT.new
    elsif v.is_a?(FalseT)
      TrueT.new
    else
      raise "invalid type"
    end
  end
end

class S2IT
  def initialize(@t : Term)
  end

  def eval
    v = @t.eval
    i = 0i64
    v.as(StringT).s.each_char do |ch|
      i *= 94
      i += STR_TBL_REV[ch - '!'] - '!'
    end
    IntegerT.new(i)
  end
end

class I2ST
  def initialize(@t : Term)
  end

  def eval
    v = @t.eval.as(IntegerT).v
    s = [] of Char
    while v > 0
      s << STR_TBL[v % 94]
      v //= 94
    end
    StringT.new(s.reverse.join, true)
  end
end

abstract class BinaryIntT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    v0 = @t0.eval.as(IntegerT).v
    v1 = @t1.eval.as(IntegerT).v
    IntegerT.new(op(v0, v1))
  end

  abstract def op(v0, v1)
end

class AddT < BinaryIntT
  def op(v0, v1)
    v0 + v1
  end
end

class SubT < BinaryIntT
  def op(v0, v1)
    v0 - v1
  end
end

class MulT < BinaryIntT
  def op(v0, v1)
    v0 * v1
  end
end

class DivT < BinaryIntT
  def op(v0, v1)
    v0.tdiv(v1)
  end
end

class ModT < BinaryIntT
  def op(v0, v1)
    v0.remainder(v1)
  end
end

class LessT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    v0 = @t0.eval.as(IntegerT).v
    v1 = @t1.eval.as(IntegerT).v
    return v0 < v1 ? TrueT.new : FalseT.new
  end
end

class GreatT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    v0 = @t0.eval.as(IntegerT).v
    v1 = @t1.eval.as(IntegerT).v
    return v0 > v1 ? TrueT.new : FalseT.new
  end
end

class EqT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    case @t0
    when IntegerT
      return @t0.as(IntegerT).v == @t1.as(IntegerT).v ? TrueT.new : FalseT.new
    when StringT
      return @t0.as(StringT).s == @t1.as(StringT).s ? TrueT.new : FalseT.new
    when TrueT
      @t1.is_a?(TrueT) ? TrueT.new : FalseT.new
    when FalseT
      @t1.is_a?(FalseT) ? TrueT.new : FalseT.new
    else
      raise "invalid type #{@t0}"
    end
  end
end

class OrT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    case @t0
    when TrueT
      @t0
    when FalseT
      @t1.is_a?(TrueT) ? @t1 : @t0
    else
      raise "invalid type #{@t0}"
    end
  end
end

class AndT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    case @t0
    when TrueT
      @t1.is_a?(TrueT) ? @t1 : @t0
    when FalseT
      @t0
    else
      raise "invalid type #{@t0}"
    end
  end
end

class ConcatT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    s0 = @t0.eval.as(StringT).s
    s1 = @t1.eval.as(StringT).s
    return StringT.new(s0 + s1, true)
  end
end

class TakeT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    x = @t0.eval.as(IntegerT).v
    y = @t1.eval.as(StringT).s
    return StringT.new(y[...x], true)
  end
end

class DropT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    x = @t0.eval.as(IntegerT).v
    y = @t1.eval.as(StringT).s
    return StringT.new(y[x..], true)
  end
end

class LambdaT
  def initialize(@t0 : Term, @t1 : Term)
  end

  def eval
    # TODO
  end
end

class IfT
  def initialize(@t0 : Term, @t1 : Term, @t2 : Term)
  end

  def eval
    case @t0.eval
    when TrueT
      @t1.eval
    when FalseT
      @t2.eval
    else
      raise "invalid type #{@t0}"
    end
  end
end

alias Term = TrueT | FalseT | IntegerT | StringT | NegT | NotT | S2IT | I2ST | AddT | SubT | MulT | DivT | ModT | LessT | GreatT | EqT | OrT | AndT | ConcatT | TakeT | DropT | LambdaT | IfT

class Parser
  def initialize(program : String)
    @terms = program.split
    @pos = 0
  end

  def parse
    opcode = @terms[@pos][0]
    rest = @terms[@pos][1..]
    @pos += 1
    case opcode
    when 'T'
      return TrueT.new
    when 'F'
      return FalseT.new
    when 'I'
      return IntegerT.new(rest)
    when 'S'
      return StringT.new(rest)
    when 'U'
      case rest[0]
      when '-'
        return NegT.new(parse)
      when '!'
        return NotT.new(parse)
      when '#'
        return S2IT.new(parse)
      when '$'
        return I2ST.new(parse)
      else
        raise "invalid term: #{@terms[@pos - 1]}"
      end
    when 'B'
      case rest[0]
      when '+'
        return AddT.new(parse, parse)
      when '-'
        return SubT.new(parse, parse)
      when '*'
        return MulT.new(parse, parse)
      when '/'
        return DivT.new(parse, parse)
      when '%'
        return ModT.new(parse, parse)
      when '<'
        return LessT.new(parse, parse)
      when '>'
        return GreatT.new(parse, parse)
      when '='
        return EqT.new(parse, parse)
      when '|'
        return OrT.new(parse, parse)
      when '&'
        return AndT.new(parse, parse)
      when '.'
        return ConcatT.new(parse, parse)
      when 'T'
        return TakeT.new(parse, parse)
      when 'D'
        return DropT.new(parse, parse)
      when '$'
        return LambdaT.new(parse, parse)
      else
        raise "invalid term: #{@terms[@pos - 1]}"
      end
    when '?'
      return IfT.new(parse, parse, parse)
    else
      raise "invalid opcode: #{opcode}"
    end
  end
end
