
aStar = {}


-- Algorytm odnajdywania drogi A*
function aStar:new()
	local instance = {}
	
	setmetatable(instance, self)
	self.__index = self
	
	return instance
end

---
--	Funkcja wykorzystywana do odnalezienia drogi do celu który chcemy zaatakować. Oznacza to że zwraca drogę obok celu i na niego nie wchodzi.
--
-- basePosition -> centralna pozycja od której liczony jest zasięg areny 
-- startPosition -> Pozycja od której rozpoczynamy szukanie
-- targetPosition -> Pozycja do której zmierzamy
-- areaSize -> wielkość areny w której poszukujemy scieżki. 
function aStar:findToAttack(startPosition, targetPosition, basePosition, areaSize)

	local path = self:findToOccupy(startPosition, targetPosition, basePosition, areaSize)
	
	return path
end

---
--	Funkcja wykorzystywana do odnalezienia drogi do celu który chcemy zając. Oznacza to że zwraca drogę idealnie do miejsca które wskaźemy.
--
-- basePosition -> centralna pozycja od której liczony jest zasięg areny 
-- startPosition -> Pozycja od której rozpoczynamy szukanie
-- targetPosition -> Pozycja do której zmierzamy
-- areaSize -> wielkość areny w której poszukujemy scieżki. 
function aStar:findToOccupy(startPosition, targetPosition, basePosition, areaSize)
	-- Wierchołki wytypowane do sprawdzenia
	local openPeak = { 
		[startPosition.x .. "-" .. startPosition.y] = {["position"] = startPosition, ["cost"] = 0, ["path"] = nil}
	}
	
	local nodes = self:createNodes(startPosition, basePosition, areaSize)
		
	-- Pobranie punktu startowego
	local current = self:firstPeak(openPeak)
	local first = true
	
	while current ~= nil do	
		local neighbors = self:neighborsPeak(nodes, current)
				
		if neighbors ~= nil then			
			for _, peak in pairs(neighbors) do
				if not first then
					peak["path"] = current
				end

				-- Sprawdzenie czy wśród sąsiadów znajduje się nasz cel
				if peak.position.x == targetPosition.x and peak.position.y == targetPosition.y then
					-- Zwrócenie scieżki
					return Path:createFromNode(peak)
				end
							
				-- Dodajemy do wierzchołka scieżkę jak do niego doszliśmy i obliczamy koszt dotarcia
				local cost = calculateCost(current, peak, creaturePosition)
				
				if cost ~= nil then
					-- Musi byc koszt zebysmy uznali kafel za "chodzacy"
					peak["cost"] = current["cost"] + cost
					-- Och to nie był nasz cel. Należy dodać wierzchołek do listy 
					local key = peak.position.x .. '-' .. peak.position.y
					openPeak[key] = peak
				end
				
				-- Usuwamy z wierzchołków sąsiada
				self:removePeak(nodes, peak.position)
			end
		end
			
		first = false
		self:removePeak(openPeak, current.position)
		
		-- Pobranie następnego elementu
		current = self:firstPeak(openPeak)	
	end
	
	-- Brak scieżki więc zwracamy pustą
	return Path:new()
end

-- Stworzenie areny którą przeszukujemy w celu odnalezienia drogi
function aStar:createNodes(startPosition, centerPosition, areaSize)
	-- Wyliczenie lewego górnego narożnika
	local left = centerPosition.x - areaSize
	local top = centerPosition.y - areaSize
	
	-- Wszystkie wierzchołki 
	local nodes = {}
	
	-- Wyliczenie wszystkich wierzchołków
	for i = 0, areaSize * 2 + 1, 1 do
		for j = 0, areaSize * 2 + 1, 1 do
			local x = left + i
			local y = top + j
			local key = x .. '-' .. y -- key is "x-y" position
			
			nodes[key] = {
				["position"] = {
					["x"] = left + i,
					["y"] = top + j,
					["z"] = startPosition.z
				},
				["cost"] = 0,
				["path"] = nil
			}
		end
	end
	
	-- Usuwamy z wierzchołków punkt startowy
	self:removePeak(nodes, startPosition)
	
	return nodes
end


-- Poszukiwanie wierzchołka o najmniejszym koszcie
function aStar:firstPeak(openPeak)
	local peak = nil
	
	for _, item in pairs(openPeak) do		
		if peak == nil or peak.cost > item.cost then
			peak = item
		end
	end
	
	return peak
end

-- Odnalezienie sąsiadów na liście
function aStar:neighborsPeak(peaks, current)
	local isEmpty = true
	local neighbors = {}
	
	local nodes = {
		{["x"] = -1, ["y"] = -1},
		{["x"] = 0, ["y"] = -1},
		{["x"] = 1, ["y"] = -1},
		
		{["x"] = -1, ["y"] = 0},
		{["x"] = 1, ["y"] = 0},
		
		{["x"] = -1, ["y"] = 1},
		{["x"] = 0, ["y"] = 1},
		{["x"] = 1, ["y"] = 1},
	}
	
	for _, item in pairs(nodes) do	
		local key = (current.position.x + item.x) .. '-' .. (current.position.y + item.y)
		local node = peaks[key]
		
		if node ~= nil then
			isEmpty = false
			neighbors[key] = node
		end
	end
	
	if isEmpty then
		return nil
	else
		return neighbors
	end
end

-- Usunięcie wierzchołka z listy
function aStar:removePeak(openPeak, position)

	-- Zbudowanie klucza
	local key = position.x .. '-' .. position.y
	
	-- Usuniecie z listy
	openPeak[key] = nil
end