--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
  local nodeAbil = getDatabaseNode().getParent()
  local nMisc2 = DB.getValue(nodeAbil, 'misc2')
  if nMisc2 then
    if nMisc2 ~= 0 then setValue(nMisc2) end
    DB.deleteChild(nodeAbil, 'misc2')
  end
end
