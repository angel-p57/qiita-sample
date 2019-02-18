require './base.rb'
module MyExample
  class ElgamalEncryptionEngine
    attr_accessor :debug_enable
    attr_reader :gamma,:n,:ft,:ftinv
    def initialize(gamma,n,ft,ftinv,debug_enable=true)
      raise ArumentError.new("gamma**n should be equal to epsilon") if gamma**n!=gamma.class.epsilon
      @gamma,@n,@debug_enable=gamma,n,debug_enable
      @ft,@ftinv=ft,ftinv
      if @debug_enable
        puts "  ** debug: initialize",
             "    Elgamal Encryption engine initialized with;",
             "    gamma=#{gamma}, n=#{n}",
             ""
      end
    end
    def create_key_pair(rval=nil)
      x = rval||rand(0...n)
      chi = @gamma**x
      if @debug_enable
        puts "  ** debug: create_key_pair",
             "    created private key x: #{x},",
             "            public key chi=gamma**x: #{chi}",
             ""
      end
      [x,chi]
    end
    def encrypt(msg,chi,rval=nil)
      # temporarily disable debug output
      save,@debug_enable = @debug_enable

      # message to a G-element translation
      myu = @ft[msg] rescue
        raise(ArgumentError.new("failed to convert message #{msg} ( #{$!} )"))

      # Diffie-Hellman private shared value calculation
      r,zeta1 = create_key_pair
      kappa = chi**r

      # conversion
      zeta2 = myu*kappa

      if @debug_enable = save
        puts "  ** debug: encrypt",
             "    translate msg = #{msg} to myu = #{myu},",
             "    created random number (private key) r = #{r},",
             "    generated cipher #1 (public key) zeta1 = #{zeta1},",
             "    using DH shared value kappa = #{kappa},",
             "    generated cipher #2 (main value) zeta2 = #{zeta2}",
             ""
      end
      [zeta1,zeta2]
    end
    def decrypt(zeta1,zeta2,x)
      # Diffie-Hellman private shared value calculation
      kappa = zeta1**x

      # inversion
      kinv = kappa.inv
      myu = zeta2*kinv

      # get message
      msg = @ftinv[myu]
      if @debug_enable
        puts "  ** debug: decrypt",
             "    cipher 1 / DH public key zeta1 = #{zeta1},",
             "    cipher 2 / main value zeta2 = #{zeta2},",
             "    DH shared value kappa = #{kappa}, and its inverse value = #{kinv},",
             "    inverse to myu = #{myu},",
             "    translate inverse to decrypted message = #{msg}",
             ""
      end
      msg
    end
  end
end
