require "./base.rb"
module MyExample
  module FiniteGroup
    # mod p における乗法群、GF(p) の機能をそのまま借用
    module Multiplicative
      # 素数に対応する GF(p) の乗法群としての機能のみを利用するクラスの生成
      def generate(p_)
        gfclass=GaloisField.generate(p_)
        Class.new(@@base).tap{|c| c.const_set(:GF,gfclass) }
      end
      module_function :generate
  
      # 基底クラス
      @@base=Class.new(Base){|c|
        attr_reader :n
        def initialize(n)
          @n=self.class::GF.new(n)
        end
        def *(elem)
          self.class.new(@n*elem.n)
        end
        def ==(elem)
          @n==elem.n
        end
        def self.epsilon
          new(1)
        end
        # 以下、データ変換用メソッド
        def to_i
          @n.to_i
        end
        def to_s
          @n.to_s
        end
        def inspect
          "\#<MG #{@n} mod #{self.class::GF::P}>"
        end
      }
    end
  end
end
