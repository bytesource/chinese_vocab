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

   # Creates a sub-hash from `self` with the keys from `keys`
   # @note keys in `keys` not present in `self` are silently ignored.
   # @return [Hash] a copy of `self`.
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


