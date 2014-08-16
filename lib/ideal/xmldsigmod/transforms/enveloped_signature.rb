module Ideal
  class Transforms < Array
    class EnvelopedSignature < Transform
      def transform
        node.xpath("descendant::ds:Signature", Xmldsig::NAMESPACES).remove
        node
      end
    end
  end
end
