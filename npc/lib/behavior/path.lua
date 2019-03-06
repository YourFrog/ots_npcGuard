Path = {}


-- Obsługa całej scieżki
function Path:new(leaf)
	local instance = {}
	
	setmetatable(instance, self)
	self.__index = self
	
	-- Ustawienie pierwszego kroku
	self.leaf = leaf
	
	return instance
end

-- Stworzenie pełnej scieżki ze zwrotki algorytmu odnajdywania
function Path:createFromNode(node)
	local leaf = Leaf:new(node)
	
	-- Szukamy kafelka od którego zaczelismy
	while node.path do
		local previous = Leaf:new()
		
		-- zapisujemy dane o node
		leaf:setData(node)
		previous:setData(node.path)
		
		-- Ustawiam relacje kafelków
		leaf:setPrevious(previous)
		previous:setNext(leaf)
		
		-- Poprzedni od teraz jest aktualnym
		leaf = previous
		
		-- Przechodzimy do następnego
		node = node.path
	end
	
	-- Zwrócenie liścia od którego zaczynamy podróż
	return Path:new(leaf)
end

-- Wykonanie jednego kroku
function Path:step(cid)
	if self.leaf == nil then
		-- Nie odnaleziono sciezki ktora mozna dotrzec do przeciwnika
		return false
	end
	
	-- Wykonanie kroku
	doTeleportThing(cid, self.leaf:getPosition(), true)
	
	-- Przesunięcie pozycji
	self.leaf = self.leaf:getNext()
	
	return true
end

function Path:isEmpty()
	return self.leaf == nil or self.data == nil
end