--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

---	This function auto-sets the second ability stat for each unmodified save to charisma for lvl 2 and up paladins.
local function prepPaladin(nodeClassLevel)
	if DB.isOwner(nodeClassLevel) then
		local nodeChar = nodeClassLevel.getChild('..')
		local nPalLvl = DB.getValue(CharManager.getClassNode(nodeChar, 'Paladin'), "level")

		if nPalLvl and nPalLvl >= 2 then -- if PC is at least a 2nd level paladin
			local sFort2Stat = DB.getValue(nodeChar, 'saves.fortitude.ability2')
			local sRef2Stat = DB.getValue(nodeChar, 'saves.reflex.ability2')
			local sWill2Stat = DB.getValue(nodeChar, 'saves.will.ability2')

			local bGMOnlyConnected = nil -- check if GM is leveling-up for players
			-- luacheck: globals table
			if table.getn(User.getActiveUsers()) == 0 and Session.IsHost then bGMOnlyConnected = true end

			local bStatChanged = nil -- check if any of the ability2 fields are still at default values
			if not sFort2Stat or not sRef2Stat or not sWill2Stat or sFort2Stat == '' or sRef2Stat == '' or sWill2Stat == '' then bStatChanged = true end

			if bStatChanged and (not Session.IsHost or bGMOnlyConnected) then -- if any ability2 are at default values, set them to charisma
				local sFormat = Interface.getString('char_message_paladinsecondsave') -- add mention of this change to the level-up messaging
				local sMsg = string.format(sFormat, DB.getValue(nodeChar, "name", ''))
				ChatManager.SystemMessage(sMsg);

				if not sFort2Stat or sFort2Stat == '' then DB.setValue(nodeChar, 'saves.fortitude.ability2', 'string', 'charisma') end
				if not sRef2Stat or sRef2Stat == '' then DB.setValue(nodeChar, 'saves.reflex.ability2', 'string', 'charisma') end
				if not sWill2Stat or sWill2Stat == '' then DB.setValue(nodeChar, 'saves.will.ability2', 'string', 'charisma') end
			end
		end
	end
end

function onInit()
	DB.addHandler(DB.getPath('charsheet.*.classlevel'), 'onUpdate', prepPaladin)
end
