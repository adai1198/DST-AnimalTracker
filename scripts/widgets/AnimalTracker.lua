local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"

local ANIMAL_TRACKER_TID = "animal_tracker_thread"
local MOLE_ANIM_TID = "mole_anim_thread"

local BEASTS =
{
    koalefant_summer = true,
    koalefant_winter = true,
    lightninggoat = true,
    warg = true,
    spat = true,
    claywarg = true,
    NOT_DANGER =
    {
        koalefant_summer = true,
        koalefant_winter = true,
        lightninggoat = true,
    }
}

local function Talk(str, later)
    local player = ThePlayer
    if later then
        player:DoTaskInTime(later, function() Talk(str) end)
    else
        player.components.talker:Say(str)
    end
end

local function findnear(prefab, rad, pos)
    local x,y,z
    local player = ConsoleCommandPlayer()
    if pos == nil then
        x,y,z = player.Transform:GetWorldPosition()
    else
        x,y,z = pos:Get()
    end
    local ents = TheSim:FindEntities(x,y,z, rad or 30)
    local closest = nil
    local closeness = nil
    for k,v in pairs(ents) do
        if v.prefab == prefab then
            if closest == nil or player:GetDistanceSqToInst(v) < closeness then
                closest = v
                closeness = player:GetDistanceSqToInst(v)
            end
        end
    end
    return closest
end

function findtag(tag, radius)
    local inst = ConsoleCommandPlayer()
    return inst ~= nil and GetClosestInstWithTag(tag, inst, radius or 1000) or nil
end


local AnimalTracker = Class(Widget, function(self)
    Widget._ctor(self, "AnimalTracker")

    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_BOTTOM)
    self.root:SetHAnchor(ANCHOR_RIGHT)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetPosition(0,0,0)

    self.button = self.root:AddChild(ImageButton("images/Animal_Track.xml", "Animal_Track.tex"))
    self.button:SetScale(1,1,1)
    self.button:SetNormalScale(.6,.6,.6)
    self.button:SetFocusScale(.8,.8,.8)
    self.button:SetPosition(-50,100,0)
    self.button:SetOnClick(function() self:OnClick() end)
end)


function GoToPointAndActivate(tpos, target)
    local player = ThePlayer
    local locomotor = player.components and player.components.locomotor or nil
    if locomotor then
        locomotor:GoToPoint(tpos)
    else
        SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, tpos.x, tpos.z)
        if target then
            local controlmods = 10 -- No idea what this is
            local canforce = false
            local action = ACTIONS.ACTIVATE
            SendRPCToServer(RPC.LeftClick, action.code, tpos.x, tpos.z, target, nil, nil, canforce, action.mod_name)
        end
    end
end


function AnimalTracker:SpawnMoleTracingAnim(pos, tpos)
    if _G.ANIMAL_TRACKER.tracking_anim == 1 then
        self:ClearMoleAnimThread()

        self.mole_anim_thread = StartThread(function()
            local steps = math.ceil(math.sqrt(distsq(pos.x, pos.z, tpos.x, tpos.z)))
            local dx = tpos.x - pos.x
            local dz = tpos.z - pos.z

            for t = 0, steps do
                local mole_move_fx = SpawnAt("mole_move_fx", pos, nil, Vector3(t/steps*dx, 0, t/steps*dz))
                mole_move_fx:DoTaskInTime(2, mole_move_fx.Remove)
                Sleep(6.5/40)
            end

            self:ClearMoleAnimThread()
        end, MOLE_ANIM_TID)
    end
end


function AnimalTracker:OnClick()
    local ret = self:FollowTrack()
    if not ret and self:IsVisible() then
        self:Hide()
    end
end


function AnimalTracker:FindLostToy()
    if not ThePlayer then return end
    local near_toy = findtag("haunted")
    local player = ThePlayer
    local locomotor = player.components and player.components.locomotor or nil
    if near_toy then
        -- Talk(string.format(STRINGS.UI.ANIMAL_TRACKER.TRACKING_FMT, near_toy.name))
        local pos = player:GetPosition()
        local tpos = near_toy:GetPosition()
        self:SpawnMoleTracingAnim(pos, tpos)
        GoToPointAndActivate(tpos)
    else
        Talk(STRINGS.UI.ANIMAL_TRACKER.NO_TOY_FOUND)
    end
    return near_toy
end


local function GetNextPos(animal_track)
    local pos = animal_track:GetPosition()
    local rot = -(animal_track.Transform:GetRotation() + 90)
    local r = 40
    local dx = r * math.cos(rot * DEGREES)
    local dz = r * math.sin(rot * DEGREES)
    return pos + Vector3(dx, 0, dz)
end


local function GetNextDirtPile(animal_track)
    local rad = 100
    local tpos = nil

    if animal_track and animal_track.prefab == "animal_track" then
        local pos = animal_track:GetPosition()
        local rot = -(animal_track.Transform:GetRotation() + 90)
        local r = 40
        local dx = r * math.cos(rot * DEGREES)
        local dz = r * math.sin(rot * DEGREES)
        rad = 3
        tpos = pos + Vector3(dx, 0, dz)
    end

    return findnear("dirtpile", rad, tpos)
end


local function WaitForPlayerIdle(player, seconds)
    repeat
        -- print("Sleep", seconds)
        Sleep(seconds)
    until not (player.sg and player.sg:HasStateTag("moving")) and
          not player:HasTag("moving")                         and
          player:HasTag("idle")                               and
          not player.components.playercontroller:IsDoingOrWorking()
end

local function UnifiedGoToPoint(player, tpos)
    -- Simply use locomotor as the check for non-server-client servers (i.e. non-cave server or host with DST-alone mod).
    local locomotor = player.components and player.components.locomotor or nil
    if locomotor then
        locomotor:GoToPoint(tpos)
    else
        SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, tpos.x, tpos.z)
    end
end

local function UnifiedActivateDirtPile(player, tpos, dirt_pile)
    -- Simply use locomotor as the check for non-server-client servers (i.e. non-cave server or host with DST-alone mod).
    local locomotor = player.components and player.components.locomotor or nil
    if locomotor then
        player:PushBufferedAction(BufferedAction(player, dirt_pile, ACTIONS.ACTIVATE))
    else
        SendRPCToServer(RPC.LeftClick, ACTIONS.ACTIVATE.code, tpos.x, tpos.z, dirt_pile)
    end
end

function AnimalTracker:HasTrack()
    return GetNextDirtPile() ~= nil
end


function AnimalTracker:FollowTrack()
    local hasTrack = self:HasTrack()

    if self.animal_tracker_thread then
        return hasTrack
    end

    if not hasTrack then
        return false
    end

    self.animal_tracker_thread = StartThread(function()
        local player = ThePlayer
        if player then
            local locomotor = player.components and player.components.locomotor or nil
            local dirt_pile = GetNextDirtPile()

            if not dirt_pile then
                Talk(STRINGS.UI.ANIMAL_TRACKER.NOT_FOUND)
            else
                while dirt_pile ~= nil do
                    local tpos = dirt_pile:GetPosition()

                    -- print("FollowTrack", "WalkTo", dirt_pile, tpos)
                    -- Talk(string.format(STRINGS.UI.ANIMAL_TRACKER.TRACKING_FMT, STRINGS.NAMES.ANIMAL_TRACK), 1)
                    UnifiedGoToPoint(player, tpos)
                    self:SpawnMoleTracingAnim(player:GetPosition(), tpos)

                    WaitForPlayerIdle(player, 10 * FRAMES)

                    if (player and player:IsValid()) and
                        (dirt_pile and dirt_pile:IsValid()) and
                        player:GetDistanceSqToInst(dirt_pile) < 4 then
                        -- print("FollowTrack", "Activate", dirt_pile, tpos)
                        -- Talk(string.format(STRINGS.UI.ANIMAL_TRACKER.INVESTIGATE_FMT, STRINGS.NAMES.DIRTPILE))
                        UnifiedActivateDirtPile(player, tpos, dirt_pile)

                        WaitForPlayerIdle(player, 10 * FRAMES)
                    else
                        -- Player interrupted
                        break
                    end

                    dirt_pile = GetNextDirtPile()
                end

                -- print("FollowTrack", "End")

                local animal_track = findnear("animal_track")
                if animal_track then
                    local x,y,z = GetNextPos(animal_track):Get()
                    local ents = TheSim:FindEntities(x,y,z, 4)
                    for k,v in pairs(ents) do
                        if BEASTS[v.prefab] then
                            local spos = player:GetPosition()
                            local tpos = v:GetPosition()
                            self:SpawnMoleTracingAnim(spos, tpos)
                            WaitForPlayerIdle(player, 10 * FRAMES)
                            Talk(string.format(STRINGS.UI.ANIMAL_TRACKER.FOUND_BEAST_FMT, v.name or v.prefab))
                            if BEASTS.NOT_DANGER[v.prefab] then
                                SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, tpos.x, tpos.z)
                            else
                                -- Go half way to the dangerous beast
                                SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, (spos.x + tpos.x) / 2, (spos.z + tpos.z) / 2)
                            end
                            break
                        end
                    end
                end
            end
        end

        self:ClearActionThread()
    end, ANIMAL_TRACKER_TID)

    return true
end


function AnimalTracker:ClearActionThread()
    if self.animal_tracker_thread then
        KillThreadsWithID(ANIMAL_TRACKER_TID)
        self.animal_tracker_thread:SetList(nil)
        self.animal_tracker_thread = nil
    end
end


function AnimalTracker:ClearMoleAnimThread()
    if self.mole_anim_thread then
        KillThreadsWithID(MOLE_ANIM_TID)
        self.mole_anim_thread:SetList(nil)
        self.mole_anim_thread = nil
    end
end


function AnimalTracker:ClearAllThreads()
    self:ClearActionThread()
    self:ClearMoleAnimThread()
end

AnimalTracker.OnRemoveEntity = AnimalTracker.ClearAllThreads
AnimalTracker.OnRemoveFromEntity = AnimalTracker.ClearAllThreads

return AnimalTracker
