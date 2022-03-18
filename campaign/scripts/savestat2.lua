--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onValueChanged()
  if window.isInitialized() then
    local sValue = getStringValue();
    if sValue == "" and baseability then
      sValue = baseability[1];
    end

    local sCharRelative = "";
    if abilityrelative then
      sCharRelative = abilityrelative[1];
    end

    if fieldabilitymod and window[fieldabilitymod[1]] then
      window[fieldabilitymod[1]].updateAbility(sCharRelative, sValue);
    end
  end
end
