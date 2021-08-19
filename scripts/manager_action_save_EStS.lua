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
	
	ActionsManager.unregisterModHandler("save");
	ActionsManager.registerModHandler("save", ActionSave.modSave);
end

function getRoll_new(rActor, sSave, ...)
	local rRoll = getRoll_old(rActor, sSave, ...); -- inheret output of previously-loaded getRoll function
	-- bmos adding second save stat
	local sAbility2
	if rActor then
		local nodeCT = ActorManager.getCTNode(rActor);
		if ActorManager.isPC(rActor) then
			local nodePC = ActorManager.getCreatureNode(rActor);
			rRoll.nMod = DB.getValue(nodePC, "saves." .. sSave .. ".total", 0);
			sAbility2 = DB.getValue(nodePC, "saves." .. sSave .. ".ability2", "");
		elseif nodeCT then
			rRoll.nMod = DB.getValue(nodeCT, sSave .. "save", 0);
		end
	end
	-- bmos adding second save ability

	-- bmos adding extra save mod to roll
	if sAbility2 and sAbility2 ~= "" then
		local sAbilityEffect2 = DataCommon.ability_ltos[sAbility2];
		if sAbilityEffect2 then
			rRoll.sDesc = rRoll.sDesc .. " [EXTRA MOD: " .. sAbilityEffect2 .. "]";
		end
	end
	-- end bmos adding extra save mod to roll

	return rRoll;
end

-- It seems I must override this function completely as it does not return data
-- I have included checks to ensure compatibility with Kelrugem's Save Versus Tags
-- Includes current 3.5E ruleset code as of 2021-08-01
function modSave_new(rSource, rTarget, rRoll, ...)
	modSave_old(rSource, rTarget, rRoll, ...)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	if rSource then
		-- Determine ability used
		local sActionStat2 = nil; -- bmos adding second save stat
		local sModStat2 = string.match(rRoll.sDesc, "%[EXTRA MOD: (%w+)%]"); -- bmos adding second save stat
		if sModStat2 then -- bmos adding second save stat
			sActionStat2 = DataCommon.ability_stol[sModStat2];
		end
		-- end bmos adding second save stat

		-- bmos adding effects for second save stat
		local nBonusStat2, nBonusEffects2 = ActorManager35E.getAbilityEffectsBonus(rSource, sActionStat2);
		if nBonusEffects2 > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat2;
		end
		-- end bmos adding effects for second save stat

		-- If effects, then add them to the in-chat roll description
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[SECOND MOD " .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[SECOND MOD " .. Interface.getString("effects_tag") .. "]";
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