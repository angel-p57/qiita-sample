#!/usr/bin/ruby

# Symmetric and Cummutative 2d Matrix Class
class SCMat2d
  # describe [[@a,@b],[@b,@c]]
  def initialize(a,b,c)
    @a,@b,@c=a,b,c
  end
  attr_reader :a,:b,:c
  # Identity Matrix
  I=new(1,0,1)

  # Matrix-matrix multiply
  def *(scm)
    bb=@b*scm.b
    self.class.new(@a*scm.a+bb,@a*scm.b+b*scm.c,bb+@c*scm.c)
  end

  # Matrix power
  def **(e)
    t,r=self,I
    while e>0
      r*=t if e.odd?
      t*=t
      e/=2
    end
    return r
  end

  # Matrix-Vector(simple array) multiply
  def convert(v)
    [@a*v[0]+@b*v[1],@b*v[0]+@c*v[1]]
  end
end

# main operation
def solve(b,c)
  cmat=SCMat2d.new(1,1,0)
  iv=(cmat**c).convert([0,1])
  r=1
  loop {
    x=cmat.convert(iv)[0]
    v=x.to_s
    v[2..-3]="(omit #{v.size-4} digits)" if r+c>25
    puts "f(#{r+c})="+v
    STDOUT.flush
    r*=b
    cmat**=b
  }
end

NR_alarm=37
# program parameter
b,c=( ARGV.size>1 ? ARGV : gets.split ).take(2).map(&:to_i)

# alarm system call for 1 second
syscall(NR_alarm,1)
solve(b,c)
