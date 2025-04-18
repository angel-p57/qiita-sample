require 'base64'
require 'securerandom'
require 'openssl'

DEFAULT_PUBLIC_EXPONENT=65537

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

def putsRSAPrivateKeyPEM(b,p,q,e,d)
    n=p*q
    dP=d%(p-1)
    dQ=d%(q-1)
    qInv=modinv(q,p)
    keyasn1 = OpenSSL::ASN1::Sequence.new(
        [0,n,e,d,p,q,dP,dQ,qInv].map{|x| OpenSSL::ASN1::Integer.new(x) }
    )
    body=Base64.strict_encode64(keyasn1.to_der)
    puts [
        '-----BEGIN RSA PRIVATE KEY-----',
        *body.scan(/.{1,64}/),
        '-----END RSA PRIVATE KEY-----'
    ]
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

def millerRabinTest(x,pseudo=false,iter=40)
    return false if x<=1
    xm=x-1
    k=0.step.find{|i| xm[i]==1 }
    y=xm>>k
    passed = false
    failed = false
    iter.times{
        a=rand(2...x)
        b=modpow(a,y,x)
        pass = b==1 || k.times.any?{
            next true if b==xm
            b=b*b%x
            false
        }
        if !pseudo
            next if pass
            return false
        end
        if pass
            return true if failed
            passed = true
        else
            return true if passed
            failed = true
        end
    }
    return !pseudo
end

PRIME_CAND210 = [
    1, 11, 13, 17, 19, 23, 29, 31,
   37, 41, 43, 47, 53, 59, 61, 67,
   71, 73, 79, 83, 89, 97,101,103,
  107,109,113,121,127,131,137,139,
  143,149,151,157,163,167,169,173,
  179,181,187,191,193,197,199,209,
]
def randSmallPrime(pinf,psup)
    qinf=(pinf-1)/210+1
    qsup=psup/210
    range=(qsup-qinf)*48
    raise "range too small for #{pinf} thru #{psup}" if range<=0
    loop{
        sr=SecureRandom.random_number(range)
        qdiff,r=sr.divmod(48)
        x=(qinf+qdiff)*210+PRIME_CAND210[r]
        next unless millerRabinTest(x)
	# warn "small prime #{x} ( #{pinf.bit_length} -> #{x.bit_length} bit )"
	return x
    }
end

def randSmallPrimeNbit(b)
    inf=1<<(b-1)
    randSmallPrime(inf,inf<<1)
end

def randPrime(pinf,psup,echeck=true)
    blen=pinf.bit_length
    loop{
        y=randSmallPrime(pinf,psup)
        return y if !echeck || (y-1)%DEFAULT_PUBLIC_EXPONENT!=0
    } if blen<1024
    sbit=blen>=2048 ? 201 : blen>=1536 ? 171 : 141
    iter=blen*5
    loop {
        p1=randSmallPrimeNbit(sbit)*2
        p2=randSmallPrimeNbit(sbit)
        next if p1.gcd(p2)!=1
        base=p1*p2
        r=modinv(p2,p1)*p2-modinv(p1,p2)*p1
        x=SecureRandom.random_number(psup-pinf)+pinf
        y=x+(r-x)%base
        iter.times{
            break if y>=psup
            return y if (!echeck||(y-1)%DEFAULT_PUBLIC_EXPONENT!=0) && millerRabinTest(y)
            y+=base
        }
    }
end

def randPseudoPrime(pinf,psup,r)
    infs = isqrt(pinf/r)+1
    sups = isqrt(psup/r)
    loop {
        p1=randPrime(infs,sups,false)
        p2=p1*r-(r-1)
        next unless millerRabinTest(p2)
        y=p1*p2
	warn "testing pprime #{p1} * #{p2}"
        next unless (y-1)%DEFAULT_PUBLIC_EXPONENT!=0 && millerRabinTest(y,true)
        dy=modinv(DEFAULT_PUBLIC_EXPONENT,y-1)
        if dy*DEFAULT_PUBLIC_EXPONENT/(y-1)%2==0
            warn("strong pseudoprime, but not destructive (dp) #{y}")
            next
        end
        return y
    }
end

def main(b,r=2)
    raise "unsupported bit length #{b}" unless b==512 || b%1024==0 && b>=1024 && b<=8192
    pinf=(0xf<<(b/2-4))+(1<<(b/2-100))
    psup=1<<(b/2)
    ninf=0xb0<<(b-8)
    nsup=0xe1<<(b-8)
    e=DEFAULT_PUBLIC_EXPONENT
    loop{
        p=randPseudoPrime(pinf,psup,r)
        qinf=(ninf-1)/p+1
        qsup=nsup/p
        20.times{
            q=randPrime(qinf,qsup)
            d=modinv(e,(p-1)*(q-1))
            next if r>2 && 40.times.all?{
                m=rand(2..p-2) 
                modpow(m,e*d,p)==m
            }
            putsRSAPrivateKeyPEM(b,p,q,e,d)
            return
        }
    }
end

if ARGV.size<1
    warn "Usage: #{$0} bit-num [pp-ratio]"
    exit 1
end

main(*ARGV.map(&:to_i))
