
dofile('data/npc/lib/behavior/leaf.lua')
dofile('data/npc/lib/behavior/path.lua')
dofile('data/npc/lib/behavior/aStar.lua')
dofile('data/npc/lib/behavior/speeches.lua')


local NPC_RUNNING_STOP = 0
local NPC_RUNNING_FOLLOW = 1
local NPC_RUNNING_BACK = 2

-- Wszystkie NPC obsługiwane przez skrypt
local npcs = {}

NpcGuard = {}

-- Utworzenie strażnika
function NpcGuard:new(options)
	local instance = {}
	
	setmetatable(instance, self)
	self.__index = self
	
	-- Przypisanie opcji do obiektu
	self.options = options
	
	return instance
end

-- Uruchomienie przetwarzania skryptu dla NPC
function NpcGuard:stateStart()
	self.options.running = NPC_RUNNING_FOLLOW
end

-- Całkowite zatrzymanie przetwarzania skryptu dla npc
function NpcGuard:stateStop()
	self.options.running = NPC_RUNNING_STOP
end

-- Powrót na miejsce docelowe
function NpcGuard:stateBack()
	self.options.running = NPC_RUNNING_BACK
end

-- Czy npc aktualnie za kimś podąża
function NpcGuard:isStateFollow() 
	return self.options.running == NPC_RUNNING_FOLLOW
end

-- Czy npc aktualnie wraca na miejsce
function NpcGuard:isStateBack()
	return self.options.running == NPC_RUNNING_BACK
end

-- Czy npc aktualnie jest aktywny
function NpcGuard:isStateActive()
	return self.options.running ~= NPC_RUNNING_STOP
end

-- Sprawdzenie czy znaleźliśmy jakąś istotę do zaatakowania
function NpcGuard:isFoundTargetCreature()
	if self.options.creatureTarget == nil then
		return false
	end
	
	return isCreature(self.options.creatureTarget)
end

-- Zresetpwamoe celu na który polujemy
function NpcGuard:resetTargetCreature()
	self.options.creatureTarget = nil
end

-- Zresetowanie wszystkich ignorowanych kreatur 
function NpcGuard:resetIgnoreCreatures()
	self.options.ignoreCreatures = {}
end

-- Poszukiwanie istoty do zaatakowania
function NpcGuard:searchCreature()
	local spectators = getSpectators(self.options.basePosition, self.options.config.scanArea, self.options.config.scanArea, false, false)
	
	if spectators == nil then
		return nil
	end
	
	for i = 1, #spectators do
		local spectator = Creature(spectators[i])
		
		if self.options.ignoreCreatures[spectator:getId()] ~= 1 then 
			-- Istota nie moze byc na ignorowanej liscie
			local spectatorName = spectator:getName():lower()
			
			if spectator:isMonster() and self.options.config.ignoreMonsters[spectatorName] ~= true then
				-- Odnalezliśmy potwora
				return spectator:getId()
			end
			
			if spectator:isPlayer() and spectator:getSkull() == (SKULL_WHITE or SKULL_RED) then
				-- Odnalezliśmy gracza
				return spectator:getId()
			end
		end
	end

	-- Brak odnalezionych celów
	return nil
end

-- Powrót na pozycje początkową
function NpcGuard:moveToBasePosition(npcPosition)
	if getDistanceBetween(npcPosition, self.options.basePosition) == 0 then
		-- NPC jest na miejscu...
		return
	end

	local path = self:findPath(npcPosition, self.options.basePosition, true)
	
	if path:step(self.options.cid) == false then
		-- Nie odnaleziono sciezki ktora mozna dotrzec do przeciwnika
		speeches:random(self.options.cid, self.options.text.backWayBlocked)
		return
	end
end

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
			["rat"] = true
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
	-- Konfiguracja dla npc
	local knightGuard = NpcGuard:new({
		config = {
			-- Wielkość areny na której szukamy bandyty
			scanArea = 6,
			
			-- Wielkość areny dla której szukamy drogi
			findArea = 8,
			
			-- Konfiguracja ataku
			attack = {
				-- Jednostka czasu co ile nalezy uderzac potwora
				speed = 1000, -- Wartość w milisekundach. Czyli 1000 ms = 1 sec
			
				-- Konfiguracja zadawanych obrażeń
				damage = {
					-- Minimalne obrażenia
					min = 70,
					
					-- Maksymalne obrażenia
					max = 120
				},
			},
			
			-- Maksymalna odległość na jaką możemy oddalić się od punktu docelowego
			maxTravel = 8,
			
			-- Punkt docelowy w którym "stacjonujemy". Zostawić null
			position = nil,
			
			-- Zapisany cache do zwiększenia wydajności odnajdywania drogi
			cache = nil,
			
			-- Potwory które będą ignorowane przez npc
			ignoreMonsters = {
				["rat"] = true
			}
		},
		text = {
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
		},
		-- identyfikator
		["cid"] = cid,
		
		-- Czy npc rozpoczął swoją prace. 0 - Nic nie robi, 1 - Ściga cel, 2 - wraca na miejsce docelowe
		["running"] = NPC_RUNNING_FOLLOW,
		
		-- Identyfikator odnalezionego celu
		["creatureTarget"] = nil,
		
		-- Czy npc złapał tego kogo ścigał
		["catch"] = false,
		
		-- Pozycje początkowe NPC
		["basePosition"] = Creature(cid):getPosition(),
		
		-- Kreatury które npc powinien ignorować. Wypełnia się to automatycznie na podstawie braku scieżki
		ignoreCreatures = {}
	})


	-- Dodanie NPC do listy
	table.insert(npcs, knightGuard)
end

function onCreatureSay(cid, type, msg)      
	if msg == "start" then
		for _, npcGuard in pairs(npcs) do
			npcGuard:stateStart()	
		end
	end
	
	if msg == "stop" then
		for _, npcGuard in pairs(npcs) do
			npcGuard:stateStop()
		end
	end
end

function onThink()	
	for _, npcGuard in pairs(npcs) do		
		local startTime = os.mtime()
		npcGuard:onThink()
		local finishTime = os.mtime();
	end
end

function NpcGuard:onThink()
	if not self:isStateActive() then
		-- Nie wydano polecenia startu
		return
	end
	
	if not self:isFoundTargetCreature() then
		-- Szukamy celu
		self.options.creatureTarget = self:searchCreature()
		
		if self:isFoundTargetCreature() then
			-- Podążamy za celem
			self:stateStart()
			self.options.catch = false
			speeches:random(self.options.cid, self.options.text.find)
		end		
	end
	
	if self:isStateFollow() and not self:isFoundTargetCreature() then
		-- Dziwne nagle istota znikneła
		self:resetTargetCreature()
		
		-- Zacznij wracac na miejsce docelowe
		self:stateBack()
	end
	
	local npcPosition = Creature(self.options.cid):getPosition()
	
	-- Jeżeli odbiegliśmy zbyt daleko od docelowego miejsca to odpuszczamy
	if self:isStateFollow() and getDistanceBetween(npcPosition, self.options.basePosition) > self.options.config.maxTravel then
		self:resetTargetCreature()
		self:stateStop()
		
		speeches:random(self.options.cid, self.options.text.back)
	end
	
	if self:isStateFollow() and self:isFoundTargetCreature() then
		local creaturePosition = Creature(self.options.creatureTarget):getPosition()
			
		-- Jeżeli dystans pomiędzy celem, a npc się zbytnio zwiększył to mu odpuszczamy :)
		if getDistanceBetween(npcPosition, creaturePosition) > self.options.config.maxTravel then
			self:resetTargetCreature()
			self:stateBack()
			
			speeches:random(npc.cid, npcText.lost)
			return 
		end
		
		if self:isStateFollow() then
			-- Biegniemy do celu
			if self:moveToTarget(npcPosition, creaturePosition) == false then
				-- Odnalezienie celu nie powiodlo sie wiec wroc do poszukiwan
				self.ignoreCreatures[Creature(self.creatureTarget):getId()] = 1
				
				self:resetTargetCreature()
				self:stateBack()
			else	
				-- Ruch się powiódł możemy przeczyścić ignorowane kreatury
				self:resetIgnoreCreatures()
			end
		end
	end
		
	if self:isStateBack() then
		-- Wracamy do punktu startowego
		self:moveToBasePosition(npcPosition)
	end
end

-- Ściganie ofiary
function NpcGuard:moveToTarget(npcPosition, creaturePosition)	
	if getDistanceBetween(npcPosition, creaturePosition) == 1 then
		-- Stoimy obok gracza
		if self.eventId == nil then
			self.eventId = addEvent(self.attack, self.options.config.attack.speed, self)
		end
		
		-- Czyscimy cache
		self.options.cache = nil		
		return
	end
	
	local path = self:findPath(npcPosition, creaturePosition, false)
	
	return path:step(self.options.cid)
end

-- Obsługa zaatakowania przeciwnika
function NpcGuard:attack(npc)

	if not self:isFoundTargetCreature() then
		-- Brak celu do zaatakowania
		self.eventId = nil
		return
	end
	
	local npcPosition = Creature(self.options.cid):getPosition()
	local creaturePosition = Creature(self.options.creatureTarget):getPosition()
		
	if getDistanceBetween(npcPosition, creaturePosition) ~= 1 then
		-- Nie stoimy obok postaci wiec przestajemy atakowac
		self.eventId = nil
		return
	end
	
	doTargetCombatHealth(self.options.cid, self.options.creatureTarget, COMBAT_PHYSICALDAMAGE, self.options.config.attack.damage.min * -1, self.options.config.attack.damage.max * -1, CONST_ME_HITAREA)
	
	
	if getCreatureHealth(self.options.creatureTarget) <= 0 then
		speeches:random(self.options.cid, npcText.kill)
		self:resetTargetCreature()
	else 
		if not self.options.catch then
			self.options.catch = true
			speeches:random(self.options.cid, self.options.text.catch)
		end
	end
	
	-- Dodajemy kolejny atak do kolejki
	self.eventId = addEvent(attack, self.options.config.attack.speed, self)
end

-- Szukanie sciezki
function NpcGuard:findPath(npcPosition, creaturePosition, lastPosition)

	if self.options.cache ~= nil and self.options.cache:isEmpty() == false then		
		-- Zwracamy cache
		return self.options.cache
	end
	
	pathFinding = aStar:new()
	
	-- W zależności od wywołania szukamy innego miejsca docelowego
	if lastPosition then
		self.options.cache = pathFinding:findToOccupy(npcPosition, creaturePosition, self.options.basePosition, self.options.config.findArea)
	else
		self.options.cache = pathFinding:findToAttack(npcPosition, creaturePosition, self.options.basePosition, self.options.config.findArea)
	end
	
	return self.options.cache
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

-- Funkcja pomocna podczas debugowania
function debug(title, message)

	print("########################")
	if title ~= nil then
		print("# Title: " .. title)
	end
	
	if message ~= nil then
		print("# Message: " .. message)
	end
	
	print("########################")
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
