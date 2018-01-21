require './fg_ec.rb'

# add **, square?, square to GF 
module MyExample
  module GaloisField
    @@base.class_eval{
      def self.epsilon
        new(1)
      end
      include FiniteGroup::Common
      # see: https://mathtrain.jp/criterion
      def square?
        self.class::P==2 || self==0 || self**((self.class::P-1)/2)==1
      end
      # Tonelli's; see: http://sehermitage.web.fc2.com/cmath/cmath_11.html
      def sqrt
        return nil unless square?
        return self if self==0
        t=(self.class::P-1)
        t/=w=t&-t
        s=w.bit_length-1
        b=loop{ (c=self.class.rand).square? or break c }
        c=b**t
        xinv=inv
        r=self**((t+1)/2)
        1.upto(s-1){|i|
          d=(r*r*xinv)**(1<<s-i-1)
          r*=c if d!=1
          c*=c
        }
        r.to_i<self.class::P/2 ? r : -r
      end
    }
  end
end

# search a combination of good parameters for ECDSA
p_=89334649
GFp=MyExample::GaloisField.generate(p_)
1000.times{
  a,b=GFp.rand,GFp.rand
  ec=begin
    MyExample::FiniteGroup::EllipticCurve.generate(GFp,a,b)
  rescue
    p ["invalid ec value",a,b]
    next
  end
  10.times{
    x=GFp.rand
    y=(x*x*x+a*x+b).sqrt or next
    elem=ec.element(x,y) or raise "something wrong in sqrt calculation"
    t=elem**(p_-100000)
    n=(1..200000).find{ (t*=elem).infinity? } or break p ["rank unspecified",a,b,elem]
    n+=p_-100000
    r=n.prime_division.last
    if r[1]<2&&r[0]>500000&&r[0]<p_/10
      gamma=elem**(n/r[0])
      puts "** found: p=#{p_},a=#{a},b=#{b},q=#{r[0]},gamma=#{gamma} **"
      break
    end
    if r[1]>1
      break p ["exponent not 1",a,b,elem,n,r]
    else
      break p ["prime too small or large",a,b,elem,n,r]
    end
  } or break
}
