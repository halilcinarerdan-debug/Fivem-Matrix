-- =====================================================================
-- MATRIX MASTER MANIFESTO / client/layer_directives_client.lua
-- server/layer_directives.lua'nın 120s kapı sürgü kurulumu (/kapikiliditak)
-- ve 60s namlu değişimi (/namludegistir) sırasında oyuncuyu geçici olarak
-- "savunmasız" (silahsız, ateş edemez) bırakan minimal, yan-etkisiz kanca.
-- Mevcut client/hud.lua'ya HİÇ DOKUNULMADI -- ayrı, bağımsız bir dosya.
-- =====================================================================

local isDefenseless = false

RegisterNetEvent('matrix:client:layerDirectives:setDefenseless', function(state)
    isDefenseless = state and true or false
end)

CreateThread(function()
    while true do
        Wait(0)
        if isDefenseless then
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 47, true)  -- Weapon wheel / draw
            DisableControlAction(0, 58, true)  -- Draw weapon
            DisableControlAction(0, 263, true) -- Melee attack
            DisableControlAction(0, 264, true) -- Melee attack alt
        else
            Wait(500)
        end
    end
end)
