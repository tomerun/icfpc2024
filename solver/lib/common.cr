require "big"
STR_TBL     = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`|~ \n"
STR_TBL_REV = Array.new(STR_TBL.size) { |i| v = STR_TBL.index('!' + i); v ? '!' + v : ' ' }

macro debug(msg)
  {% if flag?(:local) %}
    STDERR.puts({{msg}})
  {% end %}
end

macro debugf(format_string, *args)
  {% if flag?(:local) %}
    STDERR.printf({{format_string}}, {{*args}})
  {% end %}
end

def crash(msg, caller_line = __LINE__)
  STDERR.puts "[ERROR] line #{caller_line}: #{msg}"
  exit
end

macro assert(cond, msg = "", caller_line = __LINE__)
  {% if flag?(:local) %}
    if !({{cond}})
      crash({{msg}}, {{caller_line}})
    end
  {% end %}
end

class VarsIdx
  property :map, :idx

  def initialize
    @map = Hash(Int64, Array(Int64)).new { |h, k| h[k] = [] of Int64 }
    @idx = 0i64
  end
end

class Ctx
  getter :bounds, :unbounds

  def initialize
    @bounds = Hash(Int64, Term).new
    @unbounds = Set(Int64).new
  end
end

class CloneCtx
  getter :exist, :map

  def initialize(@exist : Set(Int64))
    @map = Hash(Int64, Int64).new
  end

  def get(vi : Int64)
    if @map.has_key?(vi)
      @map[vi]
    elsif @exist.includes?(vi)
      nv = @exist.max + 1
      @exist << nv
      @map[vi] = nv
    else
      @map[vi] = vi
    end
  end
end

module Arity0
  def clone(cctx)
    self
  end

  def eval(ctx)
    self
  end

  def rename_vars(idx)
  end

  def substitute(vi, term, ctx)
    self
  end
end

module Arity1
  def initialize(@t : Term)
  end

  def clone(cctx)
    self.class.new(@t.clone(cctx))
  end

  def rename_vars(idx)
    @t.rename_vars(idx)
  end

  def substitute(vi, term, ctx)
    @t = @t.substitute(vi, term, ctx)
    self
  end
end

module Arity2
  def initialize(@t0 : Term, @t1 : Term)
  end

  def clone(cctx)
    self.class.new(@t0.clone(cctx), @t1.clone(cctx))
  end

  def rename_vars(idx)
    @t0.rename_vars(idx)
    @t1.rename_vars(idx)
  end

  def substitute(vi, term, ctx)
    @t0 = @t0.substitute(vi, term, ctx)
    @t1 = @t1.substitute(vi, term, ctx)
    self
  end
end

class TrueT
  include Arity0

  def to_s(io)
    io << "T"
  end

  def print(io, depth)
    io << "  " * depth << "true\n"
  end
end

class FalseT
  include Arity0

  def to_s(io)
    io << "F"
  end

  def print(io, depth)
    io << "  " * depth << "false\n"
  end
end

class IntegerT
  include Arity0
  @v : BigInt
  getter :v

  def initialize(v : Int64)
    @v = BigInt.new(v)
  end

  def initialize(@v : BigInt)
  end

  def initialize(s : String)
    @v = IntegerT.parse(s)
  end

  def self.parse(s : String)
    v = BigInt.new(0i64)
    s.each_char do |ch|
      v *= 94
      v += ch - '!'
    end
    v
  end

  def to_s(io)
    io << "I" << StringT.convert(I2ST.convert(@v).s)
  end

  def print(io, depth)
    io << "  " * depth << @v << "\n"
  end
end

class StringT
  include Arity0
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

  def to_s(io)
    io << "S" << StringT.convert(@s)
  end

  def print(io, depth)
    io << "  " * depth << "\"" << @s.gsub("\n", "\\n") << "\"\n"
  end
end

class NegT
  include Arity1

  def eval(ctx)
    v = @t.eval(ctx)
    if v.is_a?(IntegerT)
      IntegerT.new(-v.v)
    else
      self.class.new(v)
    end
  end

  def to_s(io)
    io << "U- " << @t
  end

  def print(io, depth)
    io << "  " * depth << "-\n"
    @t.print(io, depth + 1)
  end
end

class NotT
  include Arity1

  def eval(ctx)
    v = @t.eval(ctx)
    if v.is_a?(TrueT)
      FalseT.new
    elsif v.is_a?(FalseT)
      TrueT.new
    else
      self.class.new(v)
    end
  end

  def to_s(io)
    io << "U! " << @t
  end

  def print(io, depth)
    io << "  " * depth << "!\n"
    @t.print(io, depth + 1)
  end
end

class S2IT
  include Arity1

  def eval(ctx)
    v = @t.eval(ctx)
    if v.is_a?(StringT)
      i = BigInt.new(0i64)
      v.s.each_char do |ch|
        i *= 94
        i += STR_TBL_REV[ch - '!'] - '!'
      end
      IntegerT.new(i)
    else
      self.class.new(v)
    end
  end

  def to_s(io)
    io << "U# " << @t
  end

  def print(io, depth)
    io << "  " * depth << "#\n"
    @t.print(io, depth + 1)
  end
end

class I2ST
  include Arity1

  def eval(ctx)
    v = @t.eval(ctx)
    if v.is_a?(IntegerT)
      I2ST.convert(v.v)
    else
      self.class.new(v)
    end
  end

  def self.convert(v : BigInt | Int64)
    if v == 0
      StringT.new(STR_TBL[0].to_s, true)
    else
      s = [] of Char
      while v > 0
        s << STR_TBL[v % 94]
        v //= 94
      end
      StringT.new(s.reverse.join, true)
    end
  end

  def to_s(io)
    io << "U$ " << @t
  end

  def print(io, depth)
    io << "  " * depth << "$\n"
    @t.print(io, depth + 1)
  end
end

abstract class BinaryIntT
  include Arity2

  def eval(ctx)
    v0 = @t0.eval(ctx)
    v1 = @t1.eval(ctx)
    if v0.is_a?(IntegerT) && v1.is_a?(IntegerT)
      IntegerT.new(op(v0.v, v1.v))
    else
      self.class.new(v0, v1)
    end
  end

  abstract def op(v0, v1)
end

class AddT < BinaryIntT
  def op(v0, v1)
    v0 + v1
  end

  def to_s(io)
    io << "B+ " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "+\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class SubT < BinaryIntT
  def op(v0, v1)
    v0 - v1
  end

  def to_s(io)
    io << "B- " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "-\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class MulT < BinaryIntT
  def op(v0, v1)
    v0 * v1
  end

  def to_s(io)
    io << "B* " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "*\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class DivT < BinaryIntT
  def op(v0, v1)
    v0.tdiv(v1)
  end

  def to_s(io)
    io << "B/ " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "/\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class ModT < BinaryIntT
  def op(v0, v1)
    v0.remainder(v1)
  end

  def to_s(io)
    io << "B% " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "%\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class LessT
  include Arity2

  def eval(ctx)
    v0 = @t0.eval(ctx)
    v1 = @t1.eval(ctx)
    if v0.is_a?(IntegerT) && v1.is_a?(IntegerT)
      v0.v < v1.v ? TrueT.new : FalseT.new
    else
      self.class.new(v0, v1)
    end
  end

  def to_s(io)
    io << "B< " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "<\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class GreatT
  include Arity2

  def eval(ctx)
    v0 = @t0.eval(ctx)
    v1 = @t1.eval(ctx)
    if v0.is_a?(IntegerT) && v1.is_a?(IntegerT)
      v0.v > v1.v ? TrueT.new : FalseT.new
    else
      self.class.new(v0, v1)
    end
  end

  def to_s(io)
    io << "B> " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << ">\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class EqT
  include Arity2

  def eval(ctx)
    v0 = @t0.eval(ctx)
    v1 = @t1.eval(ctx)
    if v0.is_a?(IntegerT) && v1.is_a?(IntegerT)
      v0.v == v1.v ? TrueT.new : FalseT.new
    elsif v0.is_a?(StringT) && v1.is_a?(StringT)
      v0.s == v1.s ? TrueT.new : FalseT.new
    elsif v0.is_a?(TrueT) && v1.is_a?(TrueT)
      TrueT.new
    elsif v0.is_a?(FalseT) && v1.is_a?(FalseT)
      TrueT.new
    elsif v0.is_a?(TrueT) && v1.is_a?(FalseT)
      FalseT.new
    elsif v0.is_a?(FalseT) && v1.is_a?(TrueT)
      FalseT.new
    else
      self.class.new(v0, v1)
    end
  end

  def to_s(io)
    io << "B= " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "=\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class OrT
  include Arity2

  def eval(ctx)
    v0 = @t0.eval(ctx)
    v1 = @t1.eval(ctx)
    if v0.is_a?(TrueT) || v1.is_a?(TrueT)
      TrueT.new
    elsif v0.is_a?(FalseT) && v1.is_a?(FalseT)
      FalseT.new
    else
      self.class.new(v0, v1)
    end
  end

  def to_s(io)
    io << "B| " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "|\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class AndT
  include Arity2

  def eval(ctx)
    v0 = @t0.eval(ctx)
    v1 = @t1.eval(ctx)
    if v0.is_a?(FalseT) || v1.is_a?(FalseT)
      FalseT.new
    elsif v0.is_a?(TrueT) && v1.is_a?(TrueT)
      TrueT.new
    else
      self.class.new(v0, v1)
    end
  end

  def to_s(io)
    io << "B& " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "&\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class ConcatT
  include Arity2

  def eval(ctx)
    s0 = @t0.eval(ctx)
    s1 = @t1.eval(ctx)
    if s0.is_a?(StringT) && s1.is_a?(StringT)
      StringT.new(s0.s + s1.s, true)
    else
      self.class.new(s0, s1)
    end
  end

  def to_s(io)
    io << "B. " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << ".\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class TakeT
  include Arity2

  def eval(ctx)
    x = @t0.eval(ctx)
    y = @t1.eval(ctx)
    if x.is_a?(IntegerT) && y.is_a?(StringT)
      StringT.new(y.s[...x.v], true)
    else
      self.class.new(x, y)
    end
  end

  def to_s(io)
    io << "BT " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "T\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class DropT
  include Arity2

  def eval(ctx)
    x = @t0.eval(ctx)
    y = @t1.eval(ctx)
    if x.is_a?(IntegerT) && y.is_a?(StringT)
      StringT.new(y.s[x.v..], true)
    else
      self.class.new(x, y)
    end
  end

  def to_s(io)
    io << "BD " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "D\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class ApplyT
  include Arity2

  def eval(ctx)
    # puts "eval apply t0:#{@t0} t1:#{@t1}"
    # self.print(STDOUT, 0)
    lambda = @t0
    while !lambda.is_a?(LambdaT)
      lambda = lambda.eval(ctx)
    end
    if lambda.is_a?(LambdaT)
      lambda.apply(ctx, @t1).eval(ctx)
    else
      self.class.new(lambda, @t1)
    end
  end

  def to_s(io)
    io << "B$ " << @t0 << " " << @t1
  end

  def print(io, depth)
    io << "  " * depth << "apply\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
  end
end

class LambdaT
  getter :vi

  def initialize(@vi : Int64, @t0 : Term)
  end

  def clone(cctx)
    nvi = cctx.get(@vi)
    self.class.new(nvi, @t0.clone(cctx))
  end

  def eval(ctx)
    self
  end

  def apply(ctx, term : Term)
    ctx.bounds[@vi] = term
    # puts "apply lambda t0:#{@t0}"
    # self.print(STDOUT, 0)
    ret = @t0.substitute(@vi, term, ctx)
    # ret.print(STDOUT, 0)
    # puts "ctx delete #{vi}"
    ctx.bounds.delete(vi)
    ret
  end

  def rename_vars(idx)
    vi = @vi
    idx.idx += 1
    idx.map[vi] << idx.idx
    @vi = idx.idx
    @t0.rename_vars(idx)
    idx.map[vi].pop
  end

  def substitute(vi, term, ctx)
    if @vi != vi
      ctx.unbounds << @vi
      @t0 = @t0.substitute(vi, term, ctx)
      ctx.unbounds.delete(@vi)
    end
    self
  end

  def to_s(io)
    io << "L" << StringT.convert(I2ST.convert(@vi).s) << " " << @t0
  end

  def print(io, depth)
    io << "  " * depth << "L[#{@vi}]\n"
    @t0.print(io, depth + 1)
  end
end

class VarT
  def initialize(@vi : Int64)
  end

  def clone(cctx)
    VarT.new(cctx.get(@vi))
  end

  def eval(ctx)
    self
  end

  def rename_vars(idx)
    @vi = idx.map[@vi][-1]
  end

  def substitute(vi, term, ctx)
    if @vi == vi
      # puts "substitute var #{vi}"
      cctx = CloneCtx.new(ctx.unbounds + ctx.bounds.keys.to_set)
      term.clone(cctx)
    else
      self
    end
  end

  def to_s(io)
    io << "v" << StringT.convert(I2ST.convert(@vi).s)
  end

  def print(io, depth)
    io << "  " * depth << "var[#{@vi}]\n"
  end
end

class IfT
  def initialize(@t0 : Term, @t1 : Term, @t2 : Term)
  end

  def clone(cctx)
    self.class.new(@t0.clone(cctx), @t1.clone(cctx), @t2.clone(cctx))
  end

  def eval(ctx)
    cond = @t0.eval(ctx)
    if cond.is_a?(TrueT)
      @t1.eval(ctx)
    elsif cond.is_a?(FalseT)
      @t2.eval(ctx)
    else
      self.class.new(cond, @t1, @t2)
    end
  end

  def rename_vars(idx)
    @t0.rename_vars(idx)
    @t1.rename_vars(idx)
    @t2.rename_vars(idx)
  end

  def substitute(vi, term, ctx)
    @t0 = @t0.substitute(vi, term, ctx)
    @t1 = @t1.substitute(vi, term, ctx)
    @t2 = @t2.substitute(vi, term, ctx)
    self
  end

  def to_s(io)
    io << "? " << @t0 << " " << @t1 << " " << @t2
  end

  def print(io, depth)
    io << "  " * depth << "if\n"
    @t0.print(io, depth + 1)
    @t1.print(io, depth + 1)
    @t2.print(io, depth + 1)
  end
end

alias PrimitiveT = TrueT | FalseT | IntegerT | StringT
alias Term = TrueT | FalseT | IntegerT | StringT | NegT | NotT | S2IT | I2ST | AddT | SubT | MulT | DivT | ModT | LessT | GreatT | EqT | OrT | AndT | ConcatT | TakeT | DropT | ApplyT | LambdaT | VarT | IfT

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
        return ApplyT.new(parse, parse)
      else
        raise "invalid term: #{@terms[@pos - 1]}"
      end
    when 'L'
      return LambdaT.new(IntegerT.parse(rest).to_i64, parse)
    when 'v'
      return VarT.new(IntegerT.parse(rest).to_i64)
    when '?'
      return IfT.new(parse, parse, parse)
    else
      raise "invalid opcode: #{opcode}"
    end
  end
end
