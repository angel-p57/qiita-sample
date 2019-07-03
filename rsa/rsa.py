from random import randrange
from math import sqrt,ceil,floor

def randPrime(bMin,bMax):
    def isPrime(n):
        return n>1 and all((n%d!=0 for d in range(2,floor(sqrt(n))+1)))
    rMin=ceil(pow(2.0,bMin))
    rMax=ceil(pow(2.0,bMax))
    while True:
        r=randrange(rMin,rMax)
        if isPrime(r):
            return r

def egcd(a,b):
    if a==0:
        return (b,0,1)
    g,x,y=egcd(b%a,a)
    return (g,y-b//a*x,x)

def modinv(a,n):
    g,x,y=egcd(a,n)
    if g!=1:
        raise Exception('modular inverse does not exist')
    return x%n

def lcm(a,b):
    return a*b//egcd(a,b)[0]

class MyRSA:
    DEFAULT_PUBLIC_EXPONENT=17
    class PubKey:
        def __init__(self,n,e):
            self.n,self.e=n,e
        def convert(self,data):
            return pow(data,self.e,self.n)

    class PrivKey:
        def __init__(self,p,q,d):
            self.p,self.q,self.d=p,q,d
        def convert(self,data,simple):
            if simple:
                n=self.p*self.q
                return pow(data,self.d,n)
            else:
                dP=self.d%(self.p-1)
                dQ=self.d%(self.q-1)
                cP=pow(data,dP,self.p)
                cQ=pow(data,dQ,self.q)
                qInv=modinv(self.q,self.p)
                return cQ+(cP-cQ)*qInv%self.p*self.q

    @classmethod
    def genKeyPair(cls,b=32,e=DEFAULT_PUBLIC_EXPONENT):
        h=b/2.0
        while True:
            p=randPrime(h,h+0.5)
            q=randPrime(h-1.0,h-0.5)
            try:
                d=modinv(e,lcm(p-1,q-1))
            except:
                continue
            n=p*q
            return (cls.PubKey(n,e),cls.PrivKey(p,q,d))

    @classmethod
    def encrypt(cls,pubkey,pdata):
        return pubkey.convert(pdata)

    @classmethod
    def decrypt(cls,privkey,cdata,simple=True):
        return privkey.convert(cdata,simple)

    @classmethod
    def signature(cls,privkey,msg,simple=True):
        return privkey.convert(msg,simple)

    @classmethod
    def verify(cls,pubkey,msg,sign):
        return msg==pubkey.convert(sign)

if __name__=='__main__':
    pubkey,privkey=MyRSA.genKeyPair()
    data=randrange(1,pubkey.n)
    edata=MyRSA.encrypt(pubkey,data)
    ddata1=MyRSA.decrypt(privkey,edata,True)
    ddata2=MyRSA.decrypt(privkey,edata,False)
    sdata1=MyRSA.signature(privkey,data,True)
    sdata2=MyRSA.signature(privkey,data,False)
    vresult=MyRSA.verify(pubkey,data,sdata1)
    print("public key:",vars(pubkey))
    print("private key:",vars(privkey))
    print("original data:",data)
    print("encrypted data:",edata)
    print("decrypted data(simple):",ddata1)
    print("decrypted data(complex):",ddata2)
    print("signature(simple):",sdata1)
    print("signature(complex):",sdata2)
    print("verification result:",vresult)
