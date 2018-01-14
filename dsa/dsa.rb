require './base.rb'
module MyExample
  class DSAEngine
    attr_accessor :debug_enable
    attr_reader :gamma,:gfq,:fz,:fp
    def initialize(gamma,q,fz,fp,debug_enable=true)
      gfq=GaloisField.generate(q)
      raise ArumentError.new("gamma**q should be equal to epsilon") if gamma**q!=gamma.class.epsilon
      @gamma,@gfq,@debug_enable=gamma,gfq,debug_enable
      @fz=->msg{ gfq.new(fz[msg]) }
      @fp=->gelem{ gfq.new(fp[gelem]) }
      if @debug_enable
        puts "** DSA engine initialized with gamma=#{gamma}, q=#{gfq::P} **"
      end
    end
    def create_key_pair(rval=nil)
      x = rval||@gfq.rand
      ki = @gamma**x
      if @debug_enable
        puts "** created private key x: #{x}, public key ki=gamma**x: #{ki} **"
      end
      [x,ki]
    end
    def make_signature(msg,x,rval=nil)
      z = @fz[msg]
      k = rval||@gfq.rand
      omega=@gamma**k
      r = @fp[omega]
      s = (z+x*r)/k
      if @debug_enable
        puts "** hash of msg ( #{msg} ) is #{z} **"
        puts "** random value k=#{k} selected, and gamma**k=#{omega} **"
        puts "** signature is the pair of (r,s)=(#{r},#{s}) **"
      end
      [r,s]
    end
    def verify_signature(msg,r,s,ki)
      z = @fz[msg]
      u1 = z/s
      u2 = r/s
      omega=@gamma**u1*ki**u2
      rd = @fp[omega]
      if @debug_enable
        puts "** hash of msg ( #{msg} ) is #{z} **"
        puts "** signature is the pair of (r,s)=(#{r},#{s}) **"
        puts "** calculated u1=#{u1},u2=#{u2} **"
        puts "** gamma**u1*ki**u2=#{omega} **"
        puts "** now r(derived)=#{rd}, which #{rd==r ? 'matches' : 'does not match'} r **"
      end
      rd==r
    end
  end
end
