local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"

local function Talk(str)
    ThePlayer.components.talker:Say(str)
end

local function findnear(prefab, rad)
    local player = ConsoleCommandPlayer()
    local x,y,z = player.Transform:GetWorldPosition()
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

    self.visible = false
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
    self.button:SetOnClick(function()
        local ret = self:FollowTrack()
        if not ret then
            self:Hide()
            self.visible = false
        end
    end)
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


function SpawnMoleTracingAnim(pos, tpos)
    if _G.ANIMAL_TRACKER.tracking_anim == 1 then
        local dx = tpos.x - pos.x
        local dz = tpos.z - pos.z
        for t = 0, 40 do
            TheWorld:DoTaskInTime(t/40*6.5, function()
                local mole_move_fx = SpawnAt("mole_move_fx", pos, nil, Vector3(t/40*dx, 0, t/40*dz))
                mole_move_fx:DoTaskInTime(2, mole_move_fx.Remove)
            end)
        end
    end
end


function AnimalTracker:FindLostToy()
    if not ThePlayer then return end
    local near_toy = findtag("haunted")
    local player = ThePlayer
    local locomotor = player.components and player.components.locomotor or nil
    if near_toy then
        Talk(string.format(STRINGS.UI.ANIMAL_TRACKER.TRACKING_FMT, near_toy.name))
        local pos = player:GetPosition()
        local tpos = near_toy:GetPosition()
        SpawnMoleTracingAnim(pos, tpos)
        GoToPointAndActivate(tpos)
    else
        Talk(STRINGS.UI.ANIMAL_TRACKER.NO_TOY_FOUND)
        return false
    end
    return true
end


function AnimalTracker:FollowTrack()
    if not ThePlayer then return end
    if not ThePlayer:HasTag("idle") then return end
    local near_track = findnear("animal_track")
    local player = ThePlayer
    local locomotor = player.components and player.components.locomotor or nil
    if near_track and near_track.prefab=="animal_track" then
        Talk(string.format(STRINGS.UI.ANIMAL_TRACKER.TRACKING_FMT, STRINGS.NAMES.ANIMAL_TRACK))
        local pos = near_track:GetPosition()
        local rot = -(near_track.Transform:GetRotation()+90)
        local r = 40
        local dx = r*math.cos(rot*DEGREES)
        local dz = r*math.sin(rot*DEGREES)
        local tpos = pos+Vector3(dx, 0, dz)
        SpawnMoleTracingAnim(pos, tpos)
        GoToPointAndActivate(tpos)
    else
        near_track = findnear("dirtpile", 100)
        if near_track and near_track.prefab=="dirtpile" then
            Talk(string.format(STRINGS.UI.ANIMAL_TRACKER.FOUND_TRACK_FMT, STRINGS.NAMES.DIRTPILE))
            local pos = near_track:GetPosition()
            GoToPointAndActivate(pos, near_track)
        else
            Talk(STRINGS.UI.ANIMAL_TRACKER.NOT_FOUND)
            return false
        end
    end
    return true
end

return AnimalTracker
