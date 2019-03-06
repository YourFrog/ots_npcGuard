Leaf = {}
Path = {}
aStar = {}
speeches = {}

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

-- Wybranie losowego tekstu do wypowiedzenia
--
-- cid -> Identyfikator tego co wymawia tekst
-- arr -> tablica tekstów
function speeches:random(cid, arr)
	local text = arr[math.random(#arr)]
	
	if text == nil then
		return
	end
	
	doCreatureSay(cid, text, TALKTYPE_ORANGE_1)
end

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local researchPeak = 0

-- Ustawienia skryptu
local setting = {

	-- Podstawowa konfiguracja
	config = {
		-- Wielkość areny na której szukamy bandyty
		scanArea = 6,
		
		-- Wielkość areny dla której szukamy drogi
		findArea = 8,
		
		-- Maksymalna odległość na jaką możemy oddalić się od punktu docelowego
		maxTravel = 8,
		
		-- Punkt docelowy w którym "stacjonujemy". Zostawić null
		position = nil,
		
		-- Zapisany cache do zwiększenia wydajności odnajdywania drogi
		cache = nil,
		
		-- Potwory które będą ignorowane przez npc
		ignoreMonsters = {
			["Rat"] = true
		}
	},
	
	-- NPC które obsluguje skrypt. Należy tego nie wypełniać
	["npcs"] = {}
}

local npcText = {
	-- Namierzono nowy cel :)
	["find"] = {
		"Brac go to bandyta!!",
		"Duzo tego scierwa..",
		"Nigdy nie naprawie tego zlewu"
	},
	
	-- Cel wyszedł poza zasięg
	["lost"] = {
		"Ach, znow mi uciekl..",
	},
	
	-- Cel został zabity
	["kill"] = {
		"Gin scierwo",
	},
	
	-- Dobiegnełem do celu
	["catch"] = {
		"Zostajesz aresztowany",
	},
	
	-- Zbyt dalekie oddalenie od celu
	["back"] = {
		"Nic z tego, wracam do obozowiska",
	},
	
	-- Nie można odnaleźć scieżki powrotnej
	["backWayBlocked"] = {
		"Zastawiles mi droge.."
	}
}

function onCreatureAppear(cid)

	-- Ustawienie konfiguracji konkretnego npc
	
	table.insert(setting.npcs, {
		-- identyfikator
		["cid"] = cid,
		
		-- Czy npc rozpoczął swoją prace. 0 - Nic nie robi, 1 - Ściga cel, 2 - wraca na miejsce docelowe
		["running"] = 1,
		
		-- Identyfikator odnalezionego celu
		["creatureTarget"] = nil,
		
		-- Czy npc złapał tego kogo ścigał
		["catch"] = false,
		
		-- Pozycje początkowe NPC
		["basePosition"] = Creature(cid):getPosition(),
		
		-- Kreatury które npc powinien ignorować. Wypełnia się to automatycznie na podstawie braku scieżki
		ignoreCreatures = {}
	})
	
	npcHandler:onCreatureAppear(cid)            
end

function onCreatureDisappear(cid)                
	npcHandler:onCreatureDisappear(cid)         
end

function onCreatureMove(cid, oldPosition, newPosition)
	return true
end

function onCreatureSay(cid, type, msg)      
	if msg == "start" then
		for _, creature in pairs(setting.npcs) do
			creature.running = 1		
		end
	end
	
	if msg == "stop" then
		for _, creature in pairs(setting.npcs) do
			creature.running = 0
		end
	end
	
	npcHandler:onCreatureSay(cid, type, msg)    
	
end

function onThink()	
	for _, creature in pairs(setting.npcs) do
		local startTime = os.mtime()
		researchPeak = 0
	
		eachNpc(creature)
	
		local finishTime = os.mtime();
		--print("Zbadanych wierzcholkow: " .. researchPeak)
		--print("czas ruchu " .. finishTime - startTime .. " ms")
	end
end

function eachNpc(creature)
	if creature.running == 0 then
		-- Nie wydano polecenia startu
		return
	end
	
	if creature.creatureTarget == nil then
		-- Szukamy celu
		creature.creatureTarget = findCreature(creature)
		
	
		if creature.creatureTarget == nil then
			-- Jezeli w dalszym ciagu nie odnalezilismy celu to wracamy na miejsce docelowe
			creature.running = 2
		else
			-- Podążamy za celem
			creature.running = 1
			creature.catch = false
			speeches:random(creature.cid, npcText.find)
		end		
	end
	
	if not isCreature(creature.creatureTarget) then
		-- Dziwne nagle istota znikneła
		creature.creatureTarget = nil
		
		-- Zacznij wracac na miejsce docelowe
		creature.running = 2
	end
	
	local npcPosition = Creature(creature.cid):getPosition()
	
	-- Jeżeli odbiegliśmy zbyt daleko od docelowego miejsca to odpuszczamy
	if getDistanceBetween(npcPosition, creature.basePosition) > setting.config.maxTravel and running == 1 then
		creature.creatureTarget = nil
		creature.running = 2
		
		speeches:random(npc.cid, npcText.back)
	end
	
	if creature.running == 1 then
		local creaturePosition = Creature(creature.creatureTarget):getPosition()
			
		-- Jeżeli dystans pomiędzy celem, a npc się zbytnio zwiększył to mu odpuszczamy :)
		if getDistanceBetween(npcPosition, creaturePosition) > setting.config.maxTravel then
			creature.creatureTarget = nil
			creature.running = 2
			
			speeches:random(creature.cid, npcText.lost)
			return 
		end
		
		if creature.running == 1 then
			-- Biegniemy do celu
			if goToHunt(creature, npcPosition, creaturePosition) == false then
				-- Odnalezienie celu nie powiodlo sie wiec wroc do poszukiwan
				creature.ignoreCreatures[Creature(creature.creatureTarget):getId()] = 1
				
				creature.creatureTarget = nil
				creature.running = 2
			else	
				-- Ruch się powiódł możemy przeczyścić ignorowane kreatury
				creature.ignoreCreatures = {}
			end
		end
	end
		
	if creature.running == 2 then
		-- Wracamy do punktu startowego
		backToPosition(creature, npcPosition)
	end
end

-- Powrót na pozycje
function backToPosition(npc, npcPosition)
	if getDistanceBetween(npcPosition, npc.basePosition) == 0 then
		-- NPC jest na miejscu...
		return
	end

	local path = findPath(npc, npcPosition, npc.basePosition, true)
	
	if path:step(npc.cid) == false then
		-- Nie odnaleziono sciezki ktora mozna dotrzec do przeciwnika
		speeches:random(npc.cid, npcText.backWayBlocked)
		return
	end
end

-- Ściganie ofiary
function goToHunt(npc, npcPosition, creaturePosition)	
	if getDistanceBetween(npcPosition, creaturePosition) == 1 then
		-- Stoimy obok gracza
		doTargetCombatHealth(npc.cid, npc.creatureTarget, COMBAT_PHYSICALDAMAGE, -20, -40, CONST_ME_HITAREA)
		
		-- Czyscimy cache
		npc.cache = nil
		
		if getCreatureHealth(npc.creatureTarget) <= 0 then
			speeches:random(npc.cid, npcText.kill)
			npc.creatureTarget = nil
		else 
			if not npc.catch then
				npc.catch = true
				speeches:random(npc.cid, npcText.catch)
			end
		end
		
		return
	end
	
	local path = findPath(npc, npcPosition, creaturePosition, false)
	
	return path:step(npc.cid)
end

-- Szukanie sciezki
function findPath(npc, npcPosition, creaturePosition, lastPosition)

	if npc.cache ~= nil and npc.cache:isEmpty() == false then		
		-- Zwracamy cache
		return npc.cache
	end
	
	pathFinding = aStar:new()
	
	-- W zależności od wywołania szukamy innego miejsca docelowego
	if lastPosition then
		npc.cache = pathFinding:findToOccupy(npcPosition, creaturePosition, npc.basePosition, setting.config.findArea)
	else
		npc.cache = pathFinding:findToAttack(npcPosition, creaturePosition, npc.basePosition, setting.config.findArea)
	end
	
	return npc.cache
end

-- Obliczenie kosztu podróży na kafelek
function calculateCost(current, peak, targetPosition)


	local tile = Tile(peak.position);
	
	if tile == nil then
		-- Kafelek nie istnieje
		return nil
	end
	
	local isBlocked = tile:hasFlag(TILESTATE_IMMOVABLEBLOCKSOLID)
	
	if isBlocked then
		-- Kafelki blokujace nie posiadaja kosztu
		return nil
	end 
	
	local currentPosition = current["position"]	
	local peakPosition = peak["position"]
	
	if getTopCreature(peakPosition).uid > 0 then
		-- Na kafelek nie wolno wchodzić bo ktoś już na nim stoi
		return nil
	end

	local modifier = 0
	
	local x = currentPosition.x - peakPosition.x
	local y = currentPosition.y - peakPosition.y
	
	if x == 0 or y == 0 then
		-- Idziemy w osi OX badz OY tylko
		return 100
	end
	
	-- Idziemy na ukos
	return 140
end

-- Poszukiwanie kreatury
function findCreature(npc)

	local spectators = getSpectators(npc.basePosition, setting.config.scanArea, setting.config.scanArea, false, false)
	
	if spectators == nil then
		return nil
	end
	
	for i = 1, #spectators do
		local spectator = Creature(spectators[i])
		
		if npc.ignoreCreatures[spectator:getId()] ~= 1 then 
			-- Istota nie moze byc na ignorowanej liscie
			print(spectator:getName())
			if spectator:isMonster() and setting.config.ignoreMonsters[spectator:getName()] ~= true then
				-- Odnalezliśmy potwora
				return spectator
			end
			
			if spectator:isPlayer() and spectator:getSkull() == (SKULL_WHITE or SKULL_RED) then
				-- Odnalezliśmy gracza
				return spectator
			end
		end
	end

	-- Brak odnalezionych celów
	return nil
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
