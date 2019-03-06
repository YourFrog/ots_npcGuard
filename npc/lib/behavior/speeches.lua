
speeches = {}

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