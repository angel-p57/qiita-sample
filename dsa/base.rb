module MyExample
  # 有限群の共通機能
  module FiniteGroup
    # バイナリ法によるべき乗機能を追加するmixin
    module Common
      # 追加対象のクラスの制約条件、演算 * と単位元 epsilon の存在
      def self.included(c)
        raise TypeError.new("class #{c} does not have '*' instance method") unless c.method_defined?(:*)
        raise TypeError.new("class #{c} does not have 'epsilon' class method") unless c.singleton_class.method_defined?(:epsilon)
      end
      # 自乗/二乗
      def square
        self*self
      end
      # べき乗
      def **(r)
        raise ArgumentError.new("negative exponent is not allowed") if r.to_i<0
        pow_impl(r.to_i)
      end
      # べき乗の実装 ( バイナリ法 )
      def pow_impl(r)
        case r
        when 0; self.class.epsilon
        when 1; self
        else;   r.even? ? pow_impl(r/2).square : pow_impl(r/2).square*self
        end
      end
      private :pow_impl
    end
  end

  # 素数pに対する mod p の世界 ( 有限体Z/pZ ) を提供する
  module GaloisField
    require "prime"
    # 素数 p に対応する有限体クラスを生成する
    def generate(p_)
      raise ArgumentError.new("p=#{p_} is not prime") unless p_.prime?
      Class.new(@@base).tap{|c| c.const_set(:P,p_) }
    end
    module_function :generate
    # 各有限体共通のベースクラス
    @@base=Class.new{|c|
      # mod p の値を内部的に持つ
      def initialize(n)
        @n=n.to_i%self.class::P
      end
      # 0 以外をランダムに選ぶ
      def self.rand
        new(Kernel.rand(1...self::P))
      end
      # 四則演算、減算・除算はそれぞれ逆元を加算・乗算する
      def +(elem)
        self.class.new(@n+elem.to_i)
      end
      def -(elem)
        self+(-self.class.new(elem))
      end
      def *(elem)
        self.class.new(@n*elem.to_i)
      end
      def /(elem)
        self*self.class.new(elem).inv
      end
      # 加算・乗算の逆元
      def -@
        self.class.new(-@n)
      end
      def inv
        g,x,y=Utils.egcd(@n,self.class::P)
        raise ZeroDivisionError if g!=1
        self.class.new(x)
      end
      # mod p での平方根 ( M. Cipolla のアルゴリズム )
      # 平方根が存在しない場合は nil を返す
      # see: http://yoshiiz.blog129.fc2.com/blog-entry-415.html
      def sqrt
        gfp=self.class
        return nil unless Utils.legendre_symbol(@n,gfp::P)==1
        romega=self.class.new(0)
        while romega==0 || Utils.legendre_symbol(romega.to_i,gfp::P)!=-1
          t=gfp.rand
          romega=t*t-self
        end
        gfp2g=Class.new{
          attr_reader :x,:y
          def initialize(x,y)
            @x,@y=x,y
          end
          def self.epsilon
            new(self.class::GFP.new(1),self.class::GFP.new(0))
          end
          def *(elem)
            self.class.new(@x*elem.x+@y*elem.y*self.class::ROMEGA,@x*elem.y+@y*elem.x)
          end
          include FiniteGroup::Common
        }
        gfp2g.const_set(:GFP,gfp)
        gfp2g.const_set(:ROMEGA,romega)
        (gfp2g.new(t,gfp.new(1))**(gfp::P/2+1)).x
      end
      # 比較演算
      def ==(elem)
        to_i==elem.to_i
      end
      # データ変換
      def to_i
        @n
      end
      def to_s
        @n.to_s
      end
      def inspect
        "\#<GF #{@n} mod #{self.class::P}>"
      end
    }
  end

  module Utils
    # 拡張ユークリッドの互除法により、ax+by=gcd(a,b)のを解き、
    # g=gcd, 解の1つx,yを求め、[g,x,y]を返す
    # see: http://www.tbasic.org/reference/old/ExEuclid.html
    def egcd(a,b)
      x0,x1,y0,y1=0,1,1,0
      until b==0
        a,q,b=b,*a.divmod(b)
        x0,x1=x1-q*x0,x0
        y0,y1=y1-q*y0,y0
      end
      [a,x1,y1]
    end
    # 平方剰余を判定するルジャンドル記号(0 or 1 or -1)を求める
    # see: https://en.wikipedia.org/wiki/Legendre_symbol
    def legendre_symbol(a,m)
      t=1
      until (a%=m).zero?
        d=(a&-a).bit_length-1
        a>>=d
        t=-t if d.odd? && (m%8==3||m%8==5)
        a,m=m,a
        t=-t if a%4==3&&m%4==3
      end
      m==1 ? t : 0;
    end
    module_function :egcd, :legendre_symbol
  end
end
