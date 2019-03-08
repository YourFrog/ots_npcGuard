-- Statusy NPC
NPC_RUNNING_STOP = 0
NPC_RUNNING_FOLLOW = 1
NPC_RUNNING_BACK = 2

NpcGuard = {}

-- Utworzenie strażnika
function NpcGuard:new(options)
    local instance = {}

    setmetatable(instance, self)
    self.__index = self

    -- Przypisanie opcji do obiektu
    self.options = options

    -- Pozycje początkowe NPC
    self.options.basePosition = Creature(self.options.cid):getPosition()

    self.options.attack = {}

    -- Czy byl to pierwszy krok w ataku
    self.options.attack.fistMove = true

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
    self.options.map.ignoreCreatures = {}
end

-- Poszukiwanie istoty do zaatakowania
function NpcGuard:searchCreature()
    local spectators = getSpectators(self.options.basePosition, self.options.config.scanArea, self.options.config.scanArea, false, false)

    if spectators == nil then
        return nil
    end

    for i = 1, #spectators do
        local spectator = Creature(spectators[i])

        if self.options.map.ignoreCreatures[spectator:getId()] == nil then
            -- Istota nie moze byc na ignorowanej liscie
            local spectatorName = spectator:getName():lower()

            if spectator:isMonster() and spectator:getHealth() > 0 and self.options.config.ignoreMonsters[spectatorName] ~= true then
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

-- Czy istnieje npc dla którego pracujemy
function NpcGuard:isExists()

    if self.options.cid == nil then
        -- Nie podano identyfikatora
        return false
    end

    local creature = Creature(self.options.cid)
    return creature:isNpc()
end

-- Czy npc jest akutalnie w ruchu
function NpcGuard:isMoved()
    -- Ile npc jest wstanie pokonac w ciagu sekundy (1 000 ms)
    local speed = Npc(self.options.cid):getSpeed()

    -- Obliczamy ile czasu minelo od rozpoczecia poruszania sie
    local diff = os.mtime() - self.options.config.move.stepStart

    -- Obliczenie pokonanego dystansu
    local distanceTraveled = diff / 1000 * speed

    -- Obliczenie kosztu ruchu
    local cost = self.options.config.move.stepCost * self.options.config.move.costModifier

    -- Jezeli nie zdazylismy przebyc dystansu ktory mamy oznaczony jako do przebycia to zwroc false
    return cost > distanceTraveled
end

-- Powrót na pozycje początkową
function NpcGuard:moveToBasePosition()

    local npcPosition = Npc(self.options.cid):getPosition()

    if getDistanceBetween(npcPosition, self.options.basePosition) == 0 then
        -- NPC jest na miejscu...
        return
    end

    if self:isMoved() then
        -- Jeżeli nadal się poruszamy to nic nie rób
        return
    end

    local path = self:findPath(npcPosition, self.options.basePosition, true)
    local cost = path:step(self.options.cid)

    if cost == false then
        -- Nie odnaleziono sciezki ktora mozna dotrzec do przeciwnika
        speeches:random(self.options.cid, self.options.text.backWayBlocked)

        return false
    end

    -- Oznacz czas ruchu
    self.options.config.move.stepStart = os.mtime()
    self.options.config.move.costModifier = cost

    return true
end

-- Odłożenie zdarzenia o obsłudze npc
function NpcGuard:update()
    addEvent(self.onUpdate, self.options.updateTime, self)
end

-- Aktualizuje cel do którego zmierzamy
function NpcGuard:updateTarget()

    if self:isFoundTargetCreature() then
       return
    end

    -- Szukamy celu
    self.options.creatureTarget = self:searchCreature()

    if self:isFoundTargetCreature() then
        -- Podążamy za celem
        self:stateStart()
        self.options.catch = false

        self.options.attack.fistMove = true

        return true
    end

    return false
end

-- Zweryfikowanie celu podróży
function NpcGuard:verifyTarget()

    if not self:isStateFollow() then
        -- Jeżeli nie podążamy za celem to niema co aktualizować
        return false
    end


    if not self:isFoundTargetCreature() then
        -- Dziwne nagle istota znikneła
        self:resetTargetCreature()

        -- Zacznij wracac na miejsce docelowe
        self:stateBack()

        return true
    end

    local npcPosition = Creature(self.options.cid):getPosition()

    -- Jeżeli odbiegliśmy zbyt daleko od docelowego miejsca to odpuszczamy
    if getDistanceBetween(npcPosition, self.options.basePosition) > self.options.config.maxTravel then
        self:resetTargetCreature()
        self:stateBack()

        speeches:random(self.options.cid, self.options.text.back)

        return true
    end

    return false
end

-- Włączenie npc
function NpcGuard:enable()
    self:update()
    self:removeIgnoreCreatures()
end

--- Usunięcie istot które ignorujemy
function NpcGuard:removeIgnoreCreatures()

    -- Zabezpieczenie przed wykonywaniem skryptu dla kogoś kto nie istnieje
    if not self:isExists() then
        return
    end

    local currentTime = os.mtime()

    for key, added in pairs(self.options.map.ignoreCreatures) do

        if currentTime - added >= self.options.config.map.ignoreCreaturesLifetime then
            self.options.map.ignoreCreatures[key] = nil
        end
    end

    addEvent(self.removeIgnoreCreatures, self.options.config.map.ignoreCreaturesInterval, self)
end

function NpcGuard:onUpdate()

    -- Zabezpieczenie przed wykonywaniem skryptu dla kogoś kto nie istnieje
    if not self:isExists() then
        return
    end

    -- Odłożenie zdarzenia zaaktualizowania stanu
    self:update()

    if self:isMoved() then
        -- NPC i tak się porusza więc niema co liczyć na zapas
        return
    end

    if not self:isStateActive() then
        -- Nie wydano polecenia startu
        return
    end

    -- Zaaktualizowanie celu
    self:updateTarget()

    -- Zweryfikowanie celu za którym podążamy
    self:verifyTarget()

    if self:isStateFollow() and self:isFoundTargetCreature() then
        local npcPosition = Npc(self.options.cid):getPosition()
        local creaturePosition = Creature(self.options.creatureTarget):getPosition()

        -- Jeżeli dystans pomiędzy celem, a npc się zbytnio zwiększył to mu odpuszczamy :)
        if getDistanceBetween(npcPosition, creaturePosition) > self.options.config.maxTravel then
            self:resetTargetCreature()
            self:stateBack()

            speeches:random(self.cid, self.options.text.lost)
            return
        end

        if self:isStateFollow() then
            -- Biegniemy do celu
            if self:moveToTarget(npcPosition, creaturePosition) == false then
                local creatureId = Creature(self.options.creatureTarget):getId()
                -- Odnalezienie celu nie powiodlo sie wiec wroc do poszukiwan
                self.options.map.ignoreCreatures[creatureId] = os.mtime()

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
        self:moveToBasePosition()
    end
end

-- Ściganie ofiary
function NpcGuard:moveToTarget(npcPosition, creaturePosition)
    if getDistanceBetween(npcPosition, creaturePosition) == 1 then
        -- Stoimy obok gracza
        if self.eventId == nil then
            -- Atakuj potwora od razu jak obok niego stanełeś
            self.eventId = addEvent(self.attack, 10, self)
        end

        -- Czyscimy cache
        self.options.cache = nil
        return
    end

    local path = self:findPath(npcPosition, creaturePosition, false)

    if path:canBeMove() and self.options.attack.fistMove then
        -- Wykonalismy juz 1 krok
        self.options.attack.fistMove = false

        -- Wypowiedzmy tekst
        speeches:random(self.options.cid, self.options.text.find)
    end

    local cost = path:step(self.options.cid)

    if cost then

        -- Oznacz czas ruchu
        self.options.config.move.stepStart = os.mtime()
        self.options.config.move.costModifier = cost

        return true
    end

    return false
end

--- Usunięcie NPC
function NpcGuard:removeNpc()
    self.eventId = nil
    self.options.cid = nil
end

-- Obsługa zaatakowania przeciwnika
function NpcGuard:attack()

    -- Zabezpieczenie przed wykonywaniem skryptu dla kogoś kto nie istnieje
    if not self:isExists() then
        return
    end

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
        speeches:random(self.options.cid, self.options.text.kill)
        self:resetTargetCreature()
        self:stateBack()
    else
        if not self.options.catch then
            self.options.catch = true
            speeches:random(self.options.cid, self.options.text.catch)
        end
    end

    -- Dodajemy kolejny atak do kolejki
    self.eventId = addEvent(self.attack, self.options.config.attack.speed, self)
end

-- Szukanie sciezki
function NpcGuard:findPath(npcPosition, creaturePosition, lastPosition)

    if self.options.cache ~= nil and self.options.cache:isEmpty() == false then
        -- Zwracamy cache
        return self.options.cache
    end

    local pathFinding = aStar:new()

    -- W zależności od wywołania szukamy innego miejsca docelowego
    if lastPosition then
        self.options.cache = pathFinding:findToOccupy(npcPosition, creaturePosition, self.options.basePosition, self.options.config.findArea, self.options.heuristic)
    else
        self.options.cache = pathFinding:findToAttack(npcPosition, creaturePosition, self.options.basePosition, self.options.config.findArea, self.options.heuristic)
    end

    return self.options.cache
end