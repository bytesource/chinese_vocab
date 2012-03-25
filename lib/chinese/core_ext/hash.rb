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

end
