require "./elgamal.rb"
require "./fg_m.rb"

# Elgamal parameters
p_=464937373
n=679733
FG_M=MyExample::FiniteGroup::Multiplicative.generate(p_)

myelgamal=MyExample::ElgamalEncryptionEngine.new(
  FG_M.new(2937),
  n,
  ->msg{
    raise "msg #{msg} is not in range 1..#{p_-1}" unless (1...p_)===msg
    FG_M.new(msg)
  },
  ->myu{
    myu.to_i
  }
)

# Elgamal Encryption demonstration
msg=rand(1...n)
x,chi=myelgamal.create_key_pair
zeta1,zeta2=myelgamal.encrypt(msg,chi)
puts "encrypted the message #{msg} to ( #{zeta1},#{zeta2} )",""

msg_d=myelgamal.decrypt(zeta1,zeta2,x)
puts "decrypted the cipher data to #{msg_d}, and #{msg==msg_d ? 'succeeded' : 'failed'} in restoring the original message."
