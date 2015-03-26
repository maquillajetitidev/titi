
module Tree
  class TreeNode
    def find name
      self.each do |node| 
        if node.name == name
          return node
        end
      end
      nil
    end
  end
end
