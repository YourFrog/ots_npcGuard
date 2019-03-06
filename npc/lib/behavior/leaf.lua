Leaf = {}

-- Pojedyńczy liść ze scieżki
function Leaf:new(data)
	local instance = {
	
		-- Rodzic z którego na dany kafel wejdziemy
		previous = nil,
		
		-- Potomek na którego wejdziemy z liścia
		next = nil,
		
		-- Informacje o obecnym lisciu
		data = data or nil
	}
	
	setmetatable(instance, self)
	self.__index = self
	
	return instance
end

function Leaf:setData(node)
	self.data = node
end

function Leaf:setNext(leaf)
	self.next = leaf
end

function Leaf:getNext(leaf)
	return self.next
end

function Leaf:setPrevious(leaf)
	self.previous = leaf
end

function Leaf:getPrevious()
	return self.previous
end

function Leaf:getPosition()
	return self.data.position
end