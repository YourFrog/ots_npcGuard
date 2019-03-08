if BehaviorManager == nil then
    BehaviorManager = {}

    -- Obsługa całej scieżki
    function BehaviorManager:new()
        local instance = {}

        setmetatable(instance, self)
        self.__index = self

        -- Ustawienie pierwszego kroku
        self.npcs = {}

        return instance
    end

    --- Zwraca instancje obiektu NPC obslugiwanego przez podany cid
    --
    -- return nil - Brak npc, object - Instancja NPC
    function BehaviorManager:getInstance(cid)
        return self.npcs[cid]
    end

    --- Sprawdzenie czy istnieje juz utworzony NPC o podanym identyfikatorze
    --
    -- return True - Istnieje, False - Nie istnieje
    function BehaviorManager:has(cid)
        return self.npcs[cid] ~= nil
    end

    --- Usunięcie npc z listy i zatrzymanie jego zdarzen
    function BehaviorManager:remove(cid)
        if self:has(cid) then

            self.npcs[cid]:removeNpc()
            self.npcs[cid] = nil
        end
    end

    -- Uruchamia wszystkich NPC
    function BehaviorManager:allStart()
        for _, npc in pairs(self.npcs) do
            npc:stateStart()
        end
    end

    -- Zatrzymuje wszystkich NPC
    function BehaviorManager:allStop()
        for _, npc in pairs(self.npcs) do
            npc:stateStop()
        end
    end

    --- Tworzy nowego npc o podanej klasie
    function BehaviorManager:makeNpc(cid, type, options)

        if self:has(cid) then
            return
        end

        local npc = type:new(options)

        self.npcs[cid] = npc

        npc:enable()

        return npc
    end

    -- Utworzenie obiektu
    BehaviorManager = BehaviorManager:new()
end