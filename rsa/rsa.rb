require 'prime'

def randPrime(bMin,bMax)
    rMin=(2.0**bMin).ceil
    rMax=(2.0**bMax).ceil
    loop do
        r=rand(rMin...rMax)
        return r if r.prime?
    end
end

def egcd(a,b)
    return [b,0,1] if a==0
    g,x,y=egcd(b%a,a)
    [g,y-b/a*x,x]
end

def modinv(a,n)
    g,x,y=egcd(a,n)
    raise 'modular inverse does not exist' if g!=1
    x%n
end

def modpow(a,r,n)
    raise 'negative exponents are not supported' if r<0
    return 0 if a==0
    f=->x{
        return 1 if x==0
        t=f[x/2]
        x.odd? ? t*t*a%n : t*t%n
    }
    f[r]
end

class MyRSA
    DEFAULT_PUBLIC_EXPONENT=17
    class PubKey
        attr_reader :n
        def initialize(n,e)
            @n,@e=n,e
        end
        def convert(data)
            modpow(data,@e,@n)
        end
    end

    class PrivKey
        def initialize(p,q,d)
            @p,@q,@d=p,q,d
        end
        def convert(data,simple)
            if simple
                n=@p*@q
                modpow(data,@d,n)
            else
                dP=@d%(@p-1)
                dQ=@d%(@q-1)
                cP=modpow(data,dP,@p)
                cQ=modpow(data,dQ,@q)
                qInv=modinv(@q,@p)
                cQ+(cP-cQ)*qInv%@p*@q
            end
        end
    end

    def self.genKeyPair(b=32,e=DEFAULT_PUBLIC_EXPONENT)
        h=b/2.0
        loop do
            p=randPrime(h,h+0.5)
            q=randPrime(h-1.0,h-0.5)
            d=modinv(e,(p-1).lcm(q-1)) rescue next
            n=p*q
            return [PubKey.new(n,e),PrivKey.new(p,q,d)]
        end
    end

    def self.encrypt(pubkey,pdata)
        pubkey.convert(pdata)
    end
    def self.decrypt(privkey,edata,simple=true)
        privkey.convert(edata,simple)
    end
    def self.signature(privkey,msg,simple=true)
        privkey.convert(msg,simple)
    end
    def self.verify(pubkey,msg,sign,simple=true)
        msg==pubkey.convert(sign)
    end
end

pubkey,privkey=MyRSA.genKeyPair()
data=rand(1...pubkey.n)
edata=MyRSA.encrypt(pubkey,data)
ddata1=MyRSA.decrypt(privkey,edata,true)
ddata2=MyRSA.decrypt(privkey,edata,false)
sdata1=MyRSA.signature(privkey,data,true)
sdata2=MyRSA.signature(privkey,data,false)
vresult=MyRSA.verify(pubkey,data,sdata1)
puts "public key: #{pubkey.inspect}"
puts "private key: #{privkey.inspect}"
puts "original data: #{data}"
puts "encrypted data: #{edata}"
puts "decrypted data(simple): #{ddata1}"
puts "decrypted data(complex): #{ddata2}"
puts "signature(simple): #{sdata1}"
puts "signature(complex): #{sdata2}"
puts "verification result: #{vresult}"
