-- 
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	if User.isHost() then DB.addHandler(DB.getPath('charsheet.*.classlevel'), 'onUpdate', prepPaladin) end
end

---	This function auto-sets the second ability stat for each save to Charisma for lvl2+ Paladins.
function prepPaladin(nodeClassLevel)
	local nodeChar = nodeClassLevel.getChild('..')
	local nPalLvl = DB.getValue(CharManager.getClassNode(nodeChar, 'Paladin'), "level")

	if nPalLvl and nPalLvl >= 2 then
		local sFort2Stat = DB.getValue(nodeChar, 'saves.fortitude.ability2')
		local sRef2Stat = DB.getValue(nodeChar, 'saves.reflex.ability2')
		local sWill2Stat = DB.getValue(nodeChar, 'saves.will.ability2')

		if not sFort2Stat or sFort2Stat == '' then DB.setValue(nodeChar, 'saves.fortitude.ability2', 'string', 'charisma') end
		if not sRef2Stat or sRef2Stat == '' then DB.setValue(nodeChar, 'saves.reflex.ability2', 'string', 'charisma') end
		if not sWill2Stat or sWill2Stat == '' then DB.setValue(nodeChar, 'saves.will.ability2', 'string', 'charisma') end
	end
end