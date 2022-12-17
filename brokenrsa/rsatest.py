from enum import Enum

class OutMode(Enum):
  NOOUT = 0
  OKONLY = 1
  NGONLY = 2
  ALL = 3
  def on_ok(self):
    return self.value & 1 != 0
  def on_ng(self):
    return self.value & 2 != 0

e=11  # default public exponent

def counter(func):
  def wrapper(r,*args):
    allcount=okcount=0
    for a in r:
      allcount+=1
      if func(a,*args):
        okcount += 1
    print(f"{okcount} / {allcount} OK")
  return wrapper

@counter
def checkfermat(a,p,outmode=OutMode.ALL):
  b=pow(a,p,p)
  ok = a==b
  if ok and outmode.on_ok() or not ok and outmode.on_ng():
    print(f"a={a} -> a^p={b} mod p ( p={p} ) {'OK' if ok else 'NG'}")
  return ok
  
@counter
def checkmillerrabin(a,p,outmode=OutMode.ALL):
  d=((p-1)^(p-2))//2+1  # p=2^d*odd_num
  b=p//d
  if pow(a,b,p)==1:
    if outmode.on_ok():
      print(f"a={a}: OK ... a^b=1 mod p ( p={p}, b={b} )")
    return True
  for k in range(d.bit_length()):
    if pow(a,b,p)==p-1:
      if outmode.on_ok():
        print(f"a={a}: OK ... a^b=-1 mod p ( p={p}, b={b} )")
      return True
    b*=2
  if outmode.on_ng():
    print(f"a={a}: NG")
  return False

def rsaenc(m,n):
  return pow(m,e,n)

def rsadec_e(c,p,q):
  dp=pow(e,-1,p-1)
  dq=pow(e,-1,q-1)
  qinv=pow(q,-1,p)
  mp=pow(c,dp,p)
  mq=pow(c,dq,q)
  t=(mp-mq)*qinv%p
  return mq+t*q

def rsadec_n(c,p,q):
  d=pow(e,-1,(p-1)*(q-1))
  return pow(c,d,p*q)

@counter
def checkrsa(m,fdec,p,q,outmode=OutMode.ALL):
  c=rsaenc(m,p*q)
  mdec=fdec(c,p,q)
  ok=m==mdec
  if ok and outmode.on_ok() or not ok and outmode.on_ng():
    print(f"m={m} -> c={c} -> m(decoded)={mdec} {'OK' if ok else 'NG'}")
  return ok

if __name__=='__main__':
  print("*** rsademo ***")
  print("\n** checkfermat(range(2,10),11) **")
  checkfermat(range(2,10),11)
  print("\n** checkfermat(range(2,20),1891) **")
  checkfermat(range(2,20),1891)
  print("\n** checkfermat(range(2,560),561,OutMode.NOOUT) **")
  checkfermat(range(2,560),561,OutMode.NOOUT)
  print("\n** checkmillerrabin(range(2,12),13) **")
  checkmillerrabin(range(2,12),13)
  print("\n** checkmillerrabin(range(2,560),561,OutMode.OKONLY) **")
  checkmillerrabin(range(2,560),561,OutMode.OKONLY)
  print("\n** checkmillerrabin(range(2,1890),1891,OutMode.NOOUT) **")
  checkmillerrabin(range(2,1890),1891,OutMode.NOOUT)
  print("\n** change 'e' parameter to 17 **")
  e = 17
  print("\n** checkrsa(range(2,20),rsadec_e,1891,911) **")
  checkrsa(range(2,20),rsadec_e,1891,911)
  print("\n** checkrsa(range(2,1000),rsadec_e,1891,911,OutMode.NOOUT) **")
  checkrsa(range(2,1000),rsadec_e,1891,911,OutMode.NOOUT)
  print("\n** checkrsa(range(2,20),rsadec_n,1891,911) **")
  checkrsa(range(2,20),rsadec_n,1891,911)
  print("\n** checkrsa(range(2,1000),rsadec_n,1891,911,OutMode.NOOUT) **")
  checkrsa(range(2,1000),rsadec_n,1891,911,OutMode.NOOUT)
