_G = GLOBAL
SHORTCUT_KEY = GetModConfigData("shortcut_key")
SHORTCUT_KEY_LOST_TOY = GetModConfigData("shortcut_key_2")

if _G.LanguageTranslator.defaultlang == 'cht' then
    _G.STRINGS.UI.ANIMAL_TRACKER = {
        FOUND_TRACK_FMT = "發現一個%s...",
        TRACKING_FMT = "正在搜索%s...",
        NOT_FOUND = "沒有發現足跡！",
        NO_TOY_FOUND = "沒有發現遺失的玩具！"
    }
else
    _G.STRINGS.UI.ANIMAL_TRACKER = {
        FOUND_TRACK_FMT = "Found a fresh %s...",
        TRACKING_FMT = "Now searching for %s...",
        NOT_FOUND = "No track is found!",
        NO_TOY_FOUND = "No lost toy is found!"
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
        controls.AnimalTracker:Show()
        if _G.ANIMAL_TRACKER.notification_sound_found and not controls.AnimalTracker.visible then
            _G.TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_ding")
        end
    else
        controls.AnimalTracker:Hide()
        if _G.ANIMAL_TRACKER.notification_sound_lose and controls.AnimalTracker.visible then
            _G.TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
        end
    end
    controls.AnimalTracker.visible = onoff
end

local function CheckAndSwitchUI(inst)
    SwitchUI(_G.ANIMAL_TRACKER:num_nearby_tracks() > 0)
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

function onremove(inst)
    _G.ANIMAL_TRACKER.nearby_tracks[inst.GUID] = nil
    inst:DoTaskInTime(1, CheckAndSwitchUI)
end

AddPrefabPostInit("dirtpile", function(inst)
    -- return when it's server side
    if _G.TheWorld.ismastersim then
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
    if _G.TheWorld.ismastersim then
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
                local ret = AnimalTracker:FollowTrack()
                -- SwitchUI(ret)
            elseif SHORTCUT_KEY_LOST_TOY and key == _G[SHORTCUT_KEY_LOST_TOY] then
                local ret = AnimalTracker:FindLostToy()
                -- SwitchUI(ret)
            end
        end
    end
end


function gamepostinit()
    _G.TheInput:AddKeyHandler(KeyHandler)
end

AddGamePostInit(gamepostinit)