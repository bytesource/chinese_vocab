# encoding: utf-8

class Hash

   # Returns a copy of self with *keys removed.
   def delete_keys(*keys)
     hash = self.dup

     keys.each do |key|
       hash.delete(key)
     end
     hash
   end

   # Remove *keys from self
   def delete_keys!(*keys)
     keys.each do |key|
       self.delete(key)
     end
   end

   def slice(*keys)
     self.select { |k,v| keys.include?(k) }
   end

   def slice!(*keys)
     sub_hash = self.select { |k,v| keys.include?(k) }
     # Remove 'keys' form self:
     self.delete_keys!(*sub_hash.keys)
     sub_hash
   end
end


# hash = {a: 1, b: 2, c: 3, d: 4}
# p hash.slice(:a, :b, :z)
# p hash
# puts "==================="
# p hash.slice!(:a, :b, :z)
# p hash

