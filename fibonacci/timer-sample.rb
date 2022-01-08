#!/usr/bin/ruby

# main operation
def solve(b,c)
  # dummy
  puts "called with b,c=#{b},#{c}"
  STDOUT.flush
  sleep(10)
end

NR_alarm=37
# program parameter
b,c=( ARGV.size>1 ? ARGV : gets.split ).take(2).map(&:to_i)

# alarm system call for 1 second
syscall(NR_alarm,1)
solve(b,c)
