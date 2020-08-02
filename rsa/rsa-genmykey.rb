# abstract
#   create a 4096bit RSA SSH private key whose public key is "named".
#  "named" means, the public key contains your favorite string.
# e.g.
# $ ruby rsa-genmykey.rb /angelp57/a+cat+of+Flanders/ > angelkey
# $ ssh-keygen -y -f angelkey
# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+/angelp57/a+cat+of+Flanders/...

require 'base64'
require 'securerandom'

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
    return 1 if r==0
    return 0 if a==0
    m=1
    while r>0
      m=m*a%n if r.odd?
      a=a*a%n
      r/=2
    end
    return m
end

def hex(n,d)
    s=n.to_s(16)
    padding=d*2-s.size
    raise "too long ( n=#{s}, d=#{d} )" if padding<0
    ?0*padding+s
end

def asn1LenHstring(d,v)
    if v
        raise "too large" if d>=0x10000
        return d<0x100 ? "81" + hex(d,1) : "82" + hex(d,2)
    else
        raise "too large" if d>=0x80
        return hex(d,1)
    end
end

def asn1IntHstring(n,d,v)
    '02'+asn1LenHstring(d,v)+hex(n,d)
end

DEFAULT_PUBLIC_EXPONENT=65537
DEFAULT_PUBLIC_EXPONENT_LEN=3
def genRSAPrivateKeyPEM(p,q,b)
    d=modinv(DEFAULT_PUBLIC_EXPONENT,(p-1).lcm(q-1))
    n=p*q
    dP=d%(p-1)
    dQ=d%(q-1)
    qInv=modinv(q,p)
    #puts [n,e,d,dP,dQ,qInv].map{|a| a.to_s(16) }
    hstring=[
        0,1,false,      # fixed
        n,b/8+1,true,   # n
        DEFAULT_PUBLIC_EXPONENT,DEFAULT_PUBLIC_EXPONENT_LEN,false, # e
        d,b/8,true,     # d
        p,b/16+1,true,  # p
        q,b/16+1,true,  # q
        dP,b/16+1,true, # dP
        dQ,b/16,true,   # dQ
        qInv,b/16,true, # qInv
    ].each_slice(3).reduce(""){|s,(n,d,v)|
        s+asn1IntHstring(n,d,v)
    }
    body=Base64.strict_encode64(['30'+asn1LenHstring(hstring.size/2,true)+hstring].pack('H*'))
    [
        '-----BEGIN RSA PRIVATE KEY-----',
        *body.scan(/.{1,64}/),
        '-----END RSA PRIVATE KEY-----'
    ]*?\n
end

def isqrt(n)
    raise "unsupported" if n<0
    return 0 if n==0
    return 1 if n<4
    x=n/2
    while 0<t=(x*x-n)/(x*2)
        x-=t
    end
    x-=1 while x*x>n
    return x
end

def millerRabinTest(x,iter=40)
    return false if x<=1
    xm=x-1
    k=0.step.find{|i| xm[i]==1 }
    y=xm>>k
    iter.times.all?{
        a=rand(2...x)
        b=modpow(a,y,x)
        b==1 || k.times.any?{
            next true if b==xm
            b=b*b%x
            false
        }
    }
end

def randSmallPrime(b)
    x=SecureRandom.random_number(1<<(b-1))+(1<<(b-1))
    r=x%6
    if r>1
        x+=5-r
        d=2
    else
        x+=1-r
        d=4
    end
    until millerRabinTest(x)
        x+=d
        d=6-d
    end
    return x
end

def randPrime(pinf,psup,iter)
    loop {
        p1=randSmallPrime(171)*2
        p2=randSmallPrime(171)
        next if p1.gcd(p2)!=1
        base=p1*p2
        r=modinv(p2,p1)*p2-modinv(p1,p2)*p1
        x=SecureRandom.random_number(psup-pinf)+pinf
        y=x+(r-x)%base
        iter.times{
            break if y>=psup
            return y if (y-1)%DEFAULT_PUBLIC_EXPONENT!=0 && millerRabinTest(y)
            y+=base
        }
    }
end

def main(s,b)
    raise "unsupported bit length #{b}" if b%1024!=0 || b<3072 || b>8192
    raise "unsupported string #{s}" if s=~/[^a-zA-Z0-9+\/]/ || s.size*64>b
    top=rand(0xb0...0xe0).to_s(16)
    plen=7-(s.size+3)%8
    hinf=(top+Base64.strict_decode64(s+?A*plen).unpack('H*')[0]).to_i(16)
    hsup=(top+Base64.strict_decode64(s+?/*plen).unpack('H*')[0]).to_i(16)+1
    pinf=isqrt(hsup)+1
    pinf=(pinf<<(b/2-pinf.bit_length))+(1<<(b/2-100))
    psup=1<<(b/2)
    ninf=hinf<<(b-hinf.bit_length)
    nsup=hsup<<(b-hsup.bit_length)
    p=randPrime(pinf,psup,b*5/2)
    qinf=(ninf-1)/p+1
    qsup=nsup/p
    q=randPrime(qinf,qsup,b*5/2)
    puts genRSAPrivateKeyPEM(p,q,b)
end

if ARGV.size!=1
    warn "Usage: #{$0} embbedstring"
    warn "** embbedstring should not contain other than base64 characters **"
    exit 1
end

main(ARGV[0],4096)
