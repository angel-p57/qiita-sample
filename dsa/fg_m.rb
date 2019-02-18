require "./base.rb"
module MyExample
  module FiniteGroup
    # mod p における乗法群、GF(p) の機能をそのまま借用
    module Multiplicative
      # 素数に対応する GF(p) の乗法群としての機能のみを利用するクラスの生成
      def generate(p_)
        Class.new(GaloisField.generate(p_)){|c|
          def initialize(n)
            raise ArgumentError.new("0 is not allowed") if n%self.class::P==0
            super
          end
          def self.epsilon
            new(1)
          end
          def inspect
            "\#<MG #{@n} mod #{self.class::P}>"
          end
          private :+,:-,:/,:-@
          include Common
        }
      end
      module_function :generate
    end
  end
end
