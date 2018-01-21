require "./dsa.rb"
require "./fg_m.rb"

# DSA parameters
p_=464937373
q=679733
mydsa=MyExample::DSAEngine.new(
  MyExample::FiniteGroup::Multiplicative.generate(p_).new(2937),
  q,
  fz=->msg{ msg.hash },
  fp=->gelem{ gelem.to_i }
)

# DSA demonstration
x,chi=mydsa.create_key_pair
r,s=mydsa.make_signature("hoge",x)
puts "verify the signature with a same message:"
puts mydsa.verify_signature("hoge",r,s,chi) ? "verify O.K." : "verify N.G."
puts
puts "next, verify the signature with another message:"
puts mydsa.verify_signature("uge",r,s,chi) ? "verify O.K." : "verify N.G."
puts

puts "what if fixed k used?"
k=mydsa.gfq.rand
puts "suppose a same k=#{k} used for two messages"
mydsa.debug_enable=false
r1,s1=mydsa.make_signature("hoge",x,k)
r2,s2=mydsa.make_signature("uge",x,k)
puts "signature for 'hoge' = (#{r1},#{s1})"
puts "signature for 'uge' = (#{r2},#{s2})"
kd=(mydsa.gfq.new(fz["hoge"])-fz["uge"])/(s1-s2)
xd=(kd*s1-fz["hoge"])/r1
puts "calculated k=#{kd}, and the private key x=#{xd} leaks!"
