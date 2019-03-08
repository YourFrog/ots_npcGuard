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

--- Wykonanie jednego kroku
--
-- @return Zwraca koszt ruchu bądź false w przypadku nie wykonania ruchu
function Path:step(cid)
	if self.leaf == nil then
		-- Nie odnaleziono sciezki ktora mozna dotrzec do przeciwnika
		return false
	end

	-- Pozycja docelowa
	local targetPosition = self.leaf:getPosition()
	local sourcePosition = Creature(cid):getPosition()

	-- Wykonanie kroku
	doTeleportThing(cid, targetPosition, true)
	
	-- Przesunięcie pozycji
	self.leaf = self.leaf:getNext()

	if targetPosition.x - sourcePosition.x == 0 or targetPosition.y - sourcePosition.y == 0 then
		-- Ruch po prostej linii
		return 1.0
	end

	-- ruch po ukosie
	return 2.2
end

--- Czy można wykonać ruch
function Path:canBeMove()
	if self.leaf == nil then
		-- Nie odnaleziono sciezki ktora mozna dotrzec do przeciwnika
		return false
	end

	return true
end

function Path:isEmpty()
	return self.leaf == nil or self.data == nil
end