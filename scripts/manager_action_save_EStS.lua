-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local getRoll_old = nil
local modSave_old = nil

-- Function Overrides
function onInit()
	getRoll_old = ActionSave.getRoll;
	ActionSave.getRoll = getRoll_new;
	modSave_old = ActionSave.modSave;
	ActionSave.modSave = modSave_new;

	ActionsManager.unregisterModHandler("save");
	ActionsManager.registerModHandler("save", modSave_new);
end

function onClose()
	ActionSave.getRoll = getRoll_old;
	ActionSave.modSave = modSave_old;
end

function getRoll_new(rActor, sSave)
	local rRoll = getRoll_old(rActor, sSave); -- inheret output of previously-loaded getRoll function
	local sAbility, sAbility2 -- bmos adding second save stat
	if rActor then
		local nodeCT = ActorManager.getCTNode(rActor);
		if nodeCT then
			rRoll.nMod = DB.getValue(nodeCT, sSave .. "save", 0);
		elseif ActorManager.isPC(rActor) then
			local nodePC = ActorManager.getCreatureNode(rActor);
			rRoll.nMod = DB.getValue(nodePC, "saves." .. sSave .. ".total", 0);
			sAbility = DB.getValue(nodePC, "saves." .. sSave .. ".ability", "");
			sAbility2 = DB.getValue(nodePC, "saves." .. sSave .. ".ability2", ""); -- bmos adding second save ability
		end
	end
	if sAbility2 and sAbility2 ~= "" then -- bmos adding extra save mod to roll
		local sAbilityEffect2 = DataCommon.ability_ltos[sAbility2];
		if sAbilityEffect2 then
			rRoll.sDesc = rRoll.sDesc .. " [EXTRA MOD:" .. sAbilityEffect2 .. "]";
		end
	end -- end bmos adding extra save mod to roll
	
	return rRoll;
end

-- It seems I must override this function completely as it does not return data
-- I have included checks to ensure compatibility with Kelrugem's Save Versus Tags
-- Includes current 3.5E ruleset code as of 2021-08-01
function modSave_new(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	-- Determine save type
	local sSave = nil;
	local sSaveMatch = rRoll.sDesc:match("%[SAVE%] ([^[]+)");
	if sSaveMatch then
		sSave = StringManager.trim(sSaveMatch):lower();
	end

	if rSource then
		local bEffects = false;

		-- Determine ability used
		local sActionStat = nil;
		local sActionStat2 = nil; -- bmos adding second save stat
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		local sModStat2 = string.match(rRoll.sDesc, "%[EXTRA MOD:(%w+)%]"); -- bmos adding second save stat
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if sModStat2 then -- bmos adding second save stat
			sActionStat2 = DataCommon.ability_stol[sModStat2];
		end -- end bmos adding second save stat
		if not sActionStat then
			if sSave == "fortitude" then
				sActionStat = "constitution";
			elseif sSave == "reflex" then
				sActionStat = "dexterity";
			elseif sSave == "will" then
				sActionStat = "wisdom";
			end
		end

		-- Build save filter
		local aSaveFilter = {};
		if sSave then
			table.insert(aSaveFilter, sSave);
		end

		-- Determine flatfooted status
		local bFlatfooted = false;
		if not rRoll.bVsSave and ModifierStack.getModifierKey("ATT_FF") then
			bFlatfooted = true;
		elseif EffectManager35E.hasEffect(rSource, "Flat-footed") or EffectManager35E.hasEffect(rSource, "Flatfooted") then
			bFlatfooted = true;
		end

		-- KEL Tags
		local sEffectSpell = rRoll.tags;

		-- Get effect modifiers
		local rSaveSource = nil;
		if rRoll.sSource then
			rSaveSource = ActorManager.resolveActor(rRoll.sSource);
		end
		local aExistingBonusByType = {};

		-- KEL Adding tag information
		local aSaveEffects = EffectManager35E.getEffectsByType(rSource, "SAVE", aSaveFilter, rSaveSource, false, sEffectSpell);
		for _,v in pairs(aSaveEffects) do
			-- Determine bonus type if any
			local sBonusType = nil;
			for _,v2 in pairs(v.remainder) do
				if StringManager.contains(DataCommon.bonustypes, v2) then
					sBonusType = v2;
					break;
				end
			end
			-- Dodge bonuses stack (by rules)
			if sBonusType then
				if sBonusType == "dodge" then
					if not bFlatfooted then
						nAddMod = nAddMod + v.mod;
						bEffects = true;
					end
				elseif aExistingBonusByType[sBonusType] then
					if v.mod < 0 then
						nAddMod = nAddMod + v.mod;
					elseif v.mod > aExistingBonusByType[sBonusType] then
						nAddMod = nAddMod + v.mod - aExistingBonusByType[sBonusType];
						aExistingBonusByType[sBonusType] = v.mod;
					end
					bEffects = true;
				else
					nAddMod = nAddMod + v.mod;
					aExistingBonusByType[sBonusType] = v.mod;
					bEffects = true;
				end
			else
				nAddMod = nAddMod + v.mod;
				bEffects = true;
			end
		end

		-- Get condition modifiers
		if EffectManager35E.hasEffectCondition(rSource, "Frightened") or 
				EffectManager35E.hasEffectCondition(rSource, "Panicked") or
				EffectManager35E.hasEffectCondition(rSource, "Shaken") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		if EffectManager35E.hasEffectCondition(rSource, "Sickened") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		if sSave == "reflex" then
			if EffectManager35E.hasEffectCondition(rSource, "Slowed") then
				nAddMod = nAddMod - 1;
				bEffects = true;
			end
		end
		
		-- Get ability modifiers
		local nBonusStat, nBonusEffects = ActorManager35E.getAbilityEffectsBonus(rSource, sActionStat);
		local nBonusStat2, nBonusEffects2 = ActorManager35E.getAbilityEffectsBonus(rSource, sActionStat2); -- bmos adding effects for second save stat
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		if nBonusEffects2 > 0 then -- bmos adding effects for second save stat
			bEffects = true;
			nAddMod = nAddMod + nBonusStat2;
		end -- end bmos adding effects for second save stat
		
		-- Get negative levels
		local nNegLevelMod, nNegLevelCount = EffectManager35E.getEffectsBonus(rSource, {"NLVL"}, true);
		if nNegLevelCount > 0 then
			bEffects = true;
			nAddMod = nAddMod - nNegLevelMod;
		end

		-- If flatfooted, then add a note
		if bFlatfooted then
			table.insert(aAddDesc, "[FF]");
		end
		
		-- If effects, then add them
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end