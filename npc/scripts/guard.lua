
dofile('data/npc/lib/behavior/behaviorManager.lua')
dofile('data/npc/lib/behavior/leaf.lua')
dofile('data/npc/lib/behavior/path.lua')
dofile('data/npc/lib/behavior/aStar.lua')
dofile('data/npc/lib/behavior/speeches.lua')
dofile('data/npc/lib/behavior/types/meleeGuard.lua')

--- Usuniecie istoty
function onCreatureDisappear(cid)
    BehaviorManager:remove(cid.uid)
end

--- Istota pojawia się w grze
function onCreatureAppear(cid)
    if cid:isNpc() == false then
        -- Funkcja dostępna tylko dla NPC
        return
    end

    local uid = cid:getId()

    if BehaviorManager:has(uid) then
        -- Istnieje juz zapisany NPC o podanym identyfikatorze
        BehaviorManager:remove(uid)
    end

    -- Konfiguracja dla npc
    BehaviorManager:makeNpc(uid, NpcGuard, {
        config = {
            -- Wielkość areny na której szukamy bandyty
            scanArea = 6,

            -- Wielkość areny dla której szukamy drogi
            findArea = 8,

            -- Konfiguracja ataku
            attack = {
                -- Jednostka czasu co ile nalezy uderzac potwora
                speed = 500, -- Wartość w milisekundach. Czyli 1000 ms = 1 sec

                -- Konfiguracja zadawanych obrażeń
                damage = {
                    -- Minimalne obrażenia
                    min = 70,

                    -- Maksymalne obrażenia
                    max = 120
                },
            },

            -- Konfiguracja poruszania sie
            move = {
                -- Koszt wykonana kroku. Innymi slowy ilosc milisekund jaka zajmie postaci przejscie
                stepCost = 115,

                -- Czas w jakim postac rozpoczela ruch. Nalezy nie edytowac tej wartosci
                stepStart = 0,

                -- Modyfikator kosztu ruchu w zależnosci od kierunku ruchu
                costModifier = 1
            },

            -- Konfiguracja dotycząca mapki
            map = {
                -- Jak długo ignorowana kreatura utrzymuje sie na liscie
                ignoreCreaturesLifetime = 3000,

                -- Co ile sprawdzać ignorowane creatury
                ignoreCreaturesInterval = 1500
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
                "Brac go to bandyta!! xxx",
                "Duzo tego scierwa.. xxx ",
                "Nigdy nie naprawie tego zlewu xxx"
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

        -- Creatura którą scigamy
        ["target"] = nil,

        -- Identyfikator odnalezionego celu
        ["creatureTarget"] = nil,

        -- Czy npc złapał tego kogo ścigał
        ["catch"] = false,

        -- Dane dotyczące path findingu
        map = {
            -- Kreatury które npc powinien ignorować. Wypełnia się to automatycznie na podstawie braku scieżki
            ignoreCreatures = {},
        },

        -- Czas co jaki wykonywać aktualizacje npc
        updateTime = 10,

        -- Sposób obliczania kosztu pokonania dystansu
        heuristic = function (current, peak, targetPosition)
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

            local x = currentPosition.x - peakPosition.x
            local y = currentPosition.y - peakPosition.y

            if x == 0 or y == 0 then
                -- Idziemy w osi OX badz OY tylko
                return 100
            end

            -- Idziemy na ukos
            return 140
        end
    })
end

function onCreatureSay(cid, type, msg)
    local player = Player(cid)

    if player:getAccountType() ~= ACCOUNT_TYPE_GOD then
        -- Polecenia może wydawać jedynie GOD
        return
    end

    if msg == "start" then
        BehaviorManager:allStart()
    end

    if msg == "stop" then
        BehaviorManager:allStop()
    end
end

-- Funkcja pomocna podczas debugowania
function debug(title, message)

	print("########################")
	if title ~= nil then
		print("# Title: " .. title)
	end
	
	if message ~= nil then

        if type(message) == 'boolean' then
           if message then
               message = 'True'
           else
               message = 'False'
           end
        end
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
