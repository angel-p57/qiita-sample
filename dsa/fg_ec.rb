require "./base.rb"
module MyExample
  module FiniteGroup
    # 何らかの GF における楕円曲線
    module EllipticCurve
      # a,bを元に、GF上で y^2=x^3+ax+b の楕円曲線を提供するクラスを生成
      def generate(gf,a,b)
        a,b=gf.new(a),gf.new(b)
        # y=0の場合のxの3次方程式の重解条件を除外
        raise ArgumentError.new("4a^3+27b^2 should not be zero in mod p") if a*a*a*4+b*b*27==0
        Class.new(@@base).tap{|c|
          c.const_set(:GF,gf)
          c.const_set(:A,a)
          c.const_set(:B,b)
        }
      end
      module_function :generate
      # 楕円曲線の基底
      @@base=Class.new{|c|
        # 無限遠点はユニークなインスタンスとして扱う
        INFINITY=new
        def self.infinity
          INFINITY
        end
        def infinity?
          self.equal?(INFINITY)
        end
        def self.epsilon
          infinity
        end
        # newのラッパー、曲線上にある座標のみを受け付ける
        def self.element(x,y)
          x,y=self::GF.new(x),self::GF.new(y)
          y*y==x*x*x+self::A*x+self::B ? new(x,y) : nil
        end
        private_class_method :new
        attr_reader :x,:y
        def initialize(x,y)
          @x,@y=x,y
        end
        def ==(elem)
          elem.infinity? ? infinity? : !infinity? && @x==elem.x && @y==elem.y
        end
        # 楕円曲線上の足し算
        def +(elem)
          return elem if infinity?
          return self if elem.infinity?
          return INFINITY if @x==elem.x&&@y+elem.y==0
          # 同一要素 ( 2倍算 ) かどうかに応じて直線の傾き u の計算式を切り替える
          u=@x==elem.x ? (@x*@x*3+self.class::A)/(@y*2) : (@y-elem.y)/(@x-elem.x)
          x=u*u-@x-elem.x
          y=(@x-x)*u-@y
          # 曲線上にあるかどうかのチェックを省いて直にオブジェクトを生成する
          self.class.__send__(:new,x,y)
        end
        def -@
          infinity? ? self : self.class.__send__(:new,@x,-@y)
        end
        alias :* :+
        alias :inv :-@
        def to_s
          infinity? ? "(infinity)" : "(#{@x},#{@y})"
        end
        def inspect
          infinity? ?
            "\#<EC infinity>" :
            "\#<EC (#{@x},#{@y}) on y^2=x^3+#{self.class::A}x+#{self.class::B} mod #{self.class::GF::P}>"
        end
        include Common
      }
    end
  end
end
