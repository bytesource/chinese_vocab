# encoding: utf-8

class Array

  # Input:  [1,2,3,4,5]
  # Output: [[1, 2], [2, 3], [3, 4], [4, 5]]
  def overlap_pairs
    second = self.dup.drop(1)
    self.each_with_index.inject([]) {|acc,(item,i)|
      acc << [item,second[i]]  unless second[i].nil?
      acc
    }
  end
end
