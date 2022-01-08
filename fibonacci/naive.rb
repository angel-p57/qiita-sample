#!/usr/bin/ruby

# main operation
def solve(b,c)
  w,x=0,1
  c.times{ w,x=x,w+x }
  r=1
  loop {
    v=x.to_s
    v[2..-3]="(omit #{v.size-4} digits)" if x>=100000
    puts "f(#{r+c})="+v
    STDOUT.flush
    rn=r*b
    (rn-r).times{ w,x=x,w+x }
    r=rn
  }
end

NR_alarm=37
# program parameter
b,c=( ARGV.size>1 ? ARGV : gets.split ).take(2).map(&:to_i)

# alarm system call for 1 second
syscall(NR_alarm,1)
solve(b,c)
