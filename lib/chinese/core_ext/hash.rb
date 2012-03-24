# encoding: utf-8

class Hash

   def delete_keys(*keys)

     keys.each do |key|
       self.delete(key)
     end
     self
   end

end
