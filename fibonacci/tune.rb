#!/usr/bin/ruby

require 'bigdecimal/math'

# log-based Fibonacci estimation class
class FibES
  @@rawlast=25
  @@last2d_loop_period=300
  @@rawval=(@@rawlast-1).times.with_object([0,1]){|_,r| r<<r[-1]+r[-2] }.map(&:to_s)
  @@last2ds=(@@last2d_loop_period-2).times.with_object([0,1]){|_,r| r<<(r[-1]+r[-2])%100 }.map{|n| '%02d' % n }
  @@first2ds=[*10..99].reverse
  def initialize(prec)
    @prec=prec
    prect=prec+1
    @ln10=BigMath::log(BigDecimal('10'),prect)
    h=BigDecimal('0.5',prect)
    @log10phi=log10(h.add(BigMath::sqrt(BigDecimal('1.25'),prect),prect))
    @log10sqrt5=h.sub(log10(BigDecimal('2')).mult(h,prect),prect)
    c=BigDecimal('0.1')
    @log10first2ds=[
      0,
      *(11..99).map{|n| log10(c.mult(n,prect)) },
      BigDecimal('1')
    ]
  end

  def log10(x)
    BigMath::log(x,@prec+1).div(@ln10,@prec+1)
  end

  def self.almost0?(x,prec)
    x.add(1,prec).floor(prec-2)==1
  end
  def self.almost1?(x,prec)
    x.ceil(prec-2)==1
  end

  def estimate(n)
    return @@rawval[n] if n<@@rawlast
    log10f=@log10phi.mult(n,@prec).sub(@log10sqrt5,@prec)
    dpl=log10f.floor(0).to_i
    sz=dpl.to_s.size
    precr=@prec-sz
    raise 'lost accuracy' if precr<3
    dpr=log10f.sub(dpl,precr)
    if self.class.almost1?(dpr,precr)||self.class.almost0?(dpr,precr)
      warn "lost size accuracy where n=#{n}, log10f=#{log10f}"
      raise 'lost size accuracy where'
    end
    first2d=@@first2ds.bsearch{|x| @log10first2ds[x-10]<=dpr } or raise 'unexpected'
    lb,ub=@log10first2ds[first2d-10,2]
    if self.class.almost0?(dpr.sub(lb,precr),precr) || self.class.almost0?(ub.sub(dpr,precr),precr)
      warn "lost first 2 digit accuracy where n=#{n}, log10f=#{log10f}, first2d=#{first2d}, lower-bound=#{lb}, upper-bound=#{ub}"
      raise 'lost first 2 digit accuracy'
    end
    "#{first2d}(omit #{dpl-3} digits)#{@@last2ds[n%@@last2d_loop_period]}"
  end
end

# main operation
def solve(b,c)
  prec=50
  fibes=FibES.new(prec)
  r=1
  loop {
    n=r+c
    begin
      v=fibes.estimate(n)
    rescue
      prec+=50
      fibes=FibES.new(prec)
      next
    end
    puts "f(#{n})="+v
    STDOUT.flush
    r*=b
  }
end

NR_alarm=37
# program parameter
b,c=( ARGV.size>1 ? ARGV : gets.split ).take(2).map(&:to_i)

# alarm system call for 1 second
syscall(NR_alarm,1)
solve(b,c)
