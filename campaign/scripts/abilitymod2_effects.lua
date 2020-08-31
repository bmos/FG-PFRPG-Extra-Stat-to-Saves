-- 
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	local nodeCharCT, nodeChar = getNodeCharCT(getDatabaseNode())

	DB.addHandler(DB.getPath(nodeCharCT, 'effects.*.label'), 'onUpdate', updateEffectBonuses)
	DB.addHandler(DB.getPath(nodeCharCT, 'effects.*.isactive'), 'onUpdate', updateEffectBonuses)
	DB.addHandler(DB.getPath(nodeCharCT, 'effects'), 'onChildDeleted', updateEffectBonuses)
	DB.addHandler(DB.getPath(nodeChar, 'saves.*.ability2'), 'onUpdate', updateEffectBonuses)
	DB.addHandler(DB.getPath(nodeChar, 'classlevel'), 'onUpdate', prepPaladin)
end

function onClose()
	local nodeCharCT, nodeChar = getNodeCharCT(getDatabaseNode())

	DB.removeHandler(DB.getPath(nodeCharCT, 'effects.*.label'), 'onUpdate', updateEffectBonuses)
	DB.removeHandler(DB.getPath(nodeCharCT, 'effects.*.isactive'), 'onUpdate', updateEffectBonuses)
	DB.removeHandler(DB.getPath(nodeCharCT, 'effects'), 'onChildDeleted', updateEffectBonuses)
	DB.removeHandler(DB.getPath(nodeChar, 'saves.*.ability2'), 'onUpdate', updateEffectBonuses)
	DB.removeHandler(DB.getPath(nodeChar, 'classlevel'), 'onUpdate', prepPaladin)
end

---	Locate the effects node within the relevant player character's node within combattracker
--	@param node the databasenode passed along when this file is initialized
--	@return nodeCharCT path to this PC's databasenode "effects" in the combat tracker
function getNodeCharCT(node)
	local rActor
	local nodeCharCT
	if node.getChild('.....').getName() == 'charsheet' then
		rActor = ActorManager.getActor('pc', node.getChild('....'))
		nodeCharCT = DB.findNode(rActor['sCTNode'])
		nodeChar = node.getChild('....')
	end

	return nodeCharCT, nodeChar
end

function updateEffectBonuses()
	local rActor = ActorManager.getActor('pc', window.getDatabaseNode())

	local sFort2Stat = string.upper(window.fortitudestat2.getValue())
	local nFort2EB = math.floor(EffectManagerEStS.getEffectsBonus(rActor, sFort2Stat, true) / 2)
	local sRef2Stat = string.upper(window.reflexstat2.getValue())
	local nRef2EB = math.floor(EffectManagerEStS.getEffectsBonus(rActor, sRef2Stat, true) / 2)
	local sWill2Stat = string.upper(window.willstat2.getValue())
	local nWill2EB = math.floor(EffectManagerEStS.getEffectsBonus(rActor, sWill2Stat, true) / 2)

	window.fortitudestatmod2effects.setValue(nFort2EB)
	window.reflexstatmod2effects.setValue(nRef2EB)
	window.willstatmod2effects.setValue(nWill2EB)

	window.fortitudemisc.onValueChanged()
	window.reflexmisc.onValueChanged()
	window.willmisc.onValueChanged()
end

---	This function auto-sets the second ability stat for each save to Charisma for lvl2+ Paladins.
function prepPaladin()
	local nodeChar = getDatabaseNode().getChild('....')
	local nPalLvl = DB.getValue(CharManager.getClassNode(nodeChar, 'Paladin'), "level")

	if nPalLvl and nPalLvl >= 2 then
		local sFort2Stat = DB.getValue(nodeChar, 'saves.fortitude.ability2')
		local sRef2Stat = DB.getValue(nodeChar, 'saves.reflex.ability2')
		local sWill2Stat = DB.getValue(nodeChar, 'saves.will.ability2')

		if not sFort2Stat or sFort2Stat == '' then DB.setValue(nodeChar, 'saves.fortitude.ability2', 'string', 'charisma') end
		if not sRef2Stat or sRef2Stat == '' then DB.setValue(nodeChar, 'saves.reflex.ability2', 'string', 'charisma') end
		if not sWill2Stat or sWill2Stat == '' then DB.setValue(nodeChar, 'saves.will.ability2', 'string', 'charisma') end

		window.fortitudestatmod2effects.updateEffectBonuses()
	end
end
