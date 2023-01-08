--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
-- luacheck: globals setValue

function onInit()
	local nodeAbil = DB.getParent(getDatabaseNode())
	local nMisc2 = DB.getValue(nodeAbil, 'misc2')
	if nMisc2 then
		if nMisc2 ~= 0 then setValue(nMisc2) end
		DB.deleteChild(nodeAbil, 'misc2')
	end
end
