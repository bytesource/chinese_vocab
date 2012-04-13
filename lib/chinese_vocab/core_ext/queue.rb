# encoding: utf-8

require 'thread'

class Queue

  def to_a
    @que
  end

  # Return nil if queue is empty.
  def pop!
    pop(non_block = true)
  rescue ThreadError => e
    case e.message
    when /queue empty/
      nil
    else
      raise
    end
  end

end


