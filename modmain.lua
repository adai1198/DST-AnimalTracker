_G = GLOBAL
SHORTCUT_KEY = GetModConfigData("shortcut_key")
SHORTCUT_KEY_LOST_TOY = GetModConfigData("shortcut_key_2")

if _G.LanguageTranslator.defaultlang == 'cht' then
    _G.STRINGS.UI.ANIMAL_TRACKER = {
        INVESTIGATE_FMT = "讓我檢查這個%s...",
        TRACKING_FMT = "正在搜索%s...",
        NOT_FOUND = "沒有發現足跡！",
        NO_TOY_FOUND = "沒有發現遺失的玩具！",
        FOUND_BEAST_FMT = "發現目標：%s",
        STOP_TRACKING = "停止搜索。",
    }
else
    _G.STRINGS.UI.ANIMAL_TRACKER = {
        INVESTIGATE_FMT = "Investigating this %s...",
        TRACKING_FMT = "Now searching for %s...",
        NOT_FOUND = "No track is found!",
        NO_TOY_FOUND = "No lost toy is found!",
        FOUND_BEAST_FMT = "Target found: %s",
        STOP_TRACKING = "Stop tracking.",
    }
end
-- _G.LanguageTranslator.defaultlang
-- _G.LanguageTranslator.languages["cht"]["STRINGS.UI.ANIMAL_TRACKER.FOUND_TRACK_FMT"]

Assets =
{
    Asset("IMAGE", "images/Animal_Track.tex"),
    Asset("ATLAS", "images/Animal_Track.xml"),
}

STRINGS = _G.STRINGS
_G.ANIMAL_TRACKER = {
    UI = nil,
    tracking_anim = GetModConfigData("tracking_anim"),
    notification_sound_found = (GetModConfigData("notification_sound")==1 or GetModConfigData("notification_sound")==3),
    notification_sound_lose = (GetModConfigData("notification_sound")==2 or GetModConfigData("notification_sound")==3),
    nearby_tracks = {},
    num_nearby_tracks = function(inst)
        local count = 0
        for _ in pairs(inst.nearby_tracks) do
            count = count + 1
        end
        return count
    end,
}

local ThePlayer
local controls
local function PlayerControllerPostInit(self)
    ThePlayer = self.inst
end
AddComponentPostInit("playercontroller", PlayerControllerPostInit)

local AnimalTracker = _G.require "widgets/AnimalTracker"

local function SwitchUI(onoff)
    if onoff then
        if _G.ANIMAL_TRACKER.notification_sound_found and not controls.AnimalTracker:IsVisible() then
            _G.TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_ding")
        end
        controls.AnimalTracker:Show()
    else
        if _G.ANIMAL_TRACKER.notification_sound_lose and controls.AnimalTracker:IsVisible() then
            _G.TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
        end
        controls.AnimalTracker:Hide()
    end
end

local function CheckAndSwitchUI(inst)
    -- SwitchUI(_G.ANIMAL_TRACKER:num_nearby_tracks() > 0)
    SwitchUI(AnimalTracker:HasTrack())
end

AddClassPostConstruct("widgets/controls", function(self)
    controls = self
    controls.AnimalTracker = controls.bottomright_root:AddChild(AnimalTracker())
    _G.ANIMAL_TRACKER.UI = controls.AnimalTracker
    SwitchUI(false)
end)

local function onnear(inst)
    _G.ANIMAL_TRACKER.nearby_tracks[inst.GUID] = true
    inst:DoTaskInTime(1, CheckAndSwitchUI)
end

local function onfar(inst)
    _G.ANIMAL_TRACKER.nearby_tracks[inst.GUID] = nil
    inst:DoTaskInTime(1, CheckAndSwitchUI)
end

local function onremove(inst)
    _G.ANIMAL_TRACKER.nearby_tracks[inst.GUID] = nil
    inst:DoTaskInTime(1, CheckAndSwitchUI)
end

local function HasHUD()
    return _G.ThePlayer and (_G.ThePlayer.HUD ~= nil) or false
end

AddPrefabPostInit("dirtpile", function(inst)
    -- return when it's server side
    if not HasHUD() then
        return inst
    end
    -- only apply on client side
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(63,64)
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)
    inst:DoTaskInTime(0.1, function(inst) inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.SpecificPlayer, ThePlayer, true) end)
    inst:ListenForEvent("onremove", onremove)
    return inst
end)


AddPrefabPostInit("animal_track", function(inst)
    -- return when it's server side
    if not HasHUD() then
        return inst
    end
    -- only apply on client side
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(64,64)
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)
    inst:DoTaskInTime(0.1, function(inst) inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.SpecificPlayer, ThePlayer, true) end)
    inst:ListenForEvent("onremove", onremove)
end)


----[[ Shortcut Key ]]----
function KeyHandler(key, down)
    if down then
        if _G.ConsoleCommandPlayer() then
            if SHORTCUT_KEY and key == _G[SHORTCUT_KEY] then
                AnimalTracker:OnClick()
            elseif SHORTCUT_KEY_LOST_TOY and key == _G[SHORTCUT_KEY_LOST_TOY] then
                AnimalTracker:FindLostToy()
            end
        end
    end
end


function gamepostinit()
    _G.TheInput:AddKeyHandler(KeyHandler)
end

AddGamePostInit(gamepostinit)