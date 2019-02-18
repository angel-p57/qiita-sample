require "./elgamal.rb"
require "./fg_ec.rb"

# Elgamal parameters
p_,a,b=89334649,54079150, 64993959
n=1624057
GF=MyExample::GaloisField.generate(p_)
EC=MyExample::FiniteGroup::EllipticCurve.generate(GF,a,b)
search_width=16

myelgamal=MyExample::ElgamalEncryptionEngine.new(
  EC.element(81994458,7695874),
  n,
  ->msg{
    raise "msg #{msg} is not in range 0..#{p_/search_width-1}" unless (0...p_/search_width)===msg
    search_width.times{|i|
      x=GF.new(msg*search_width+i)
      y=(x*x*x+x*a+b).sqrt and return EC.element(x,y)
    }
    raise "failed to search an element on EC for #{msg}"
  },
  ->mu{
    mu.x.to_i/search_width
  }
)

# Elgamal Encryption demonstration
msg=rand(0...p_/search_width)
x,chi=myelgamal.create_key_pair
zeta1,zeta2=myelgamal.encrypt(msg,chi)
puts "encrypted the message #{msg} to ( #{zeta1},#{zeta2} )",""

msg_d=myelgamal.decrypt(zeta1,zeta2,x)
puts "decrypted the cipher data to #{msg_d}, and #{msg==msg_d ? 'succeeded' : 'failed'} in restoring the original message."
