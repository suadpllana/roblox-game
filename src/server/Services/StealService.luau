--[[
	The heart of the game: grab a plushie from someone else's base, carry it over
	your head and run it back to your own base before you get bonked or the owner
	tags you.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Plushies = require(ReplicatedStorage.Shared.Plushies)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlushieFactory = require(script.Parent.PlushieFactory)

local StealService = {}

local Services
local BaseService
local notify: RemoteEvent
local announce: RemoteEvent
local carriedFolder: Folder

type Carry = {
	Owner: Player,
	Slot: number,
	Entry: any,
	Model: Model,
	DiedConnection: RBXScriptConnection?,
}

local carries: { [Player]: Carry } = {}

local function aliveParts(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil, nil
	end
	return humanoid, root
end

function StealService:Init(services)
	Services = services
	BaseService = services.BaseService
	notify = Remotes.Get("Notify")
	announce = Remotes.Get("Announce")
	carriedFolder = Instance.new("Folder")
	carriedFolder.Name = "CarriedPlushies"
	carriedFolder.Parent = workspace
end

function StealService:IsCarrying(player: Player): boolean
	return carries[player] ~= nil
end

function StealService:TryStart(thief: Player, owner: Player, slot: number)
	if thief == owner or carries[thief] or not owner.Parent then
		return
	end
	if not BaseService:GetBase(thief) then
		notify:FireClient(thief, "You need a base to steal!", "error")
		return
	end
	local base = BaseService:GetBase(owner)
	if not base or base.Stealing[slot] then
		return
	end
	local reason = BaseService:GetProtectionReason(owner)
	if reason then
		notify:FireClient(thief, reason, "error")
		return
	end
	local entry = BaseService:GetEntry(owner, slot)
	if not entry then
		return
	end
	if not BaseService:FindFreeSlot(thief) then
		notify:FireClient(thief, "Your base is full! Sell something first.", "error")
		return
	end
	local humanoid, root = aliveParts(thief)
	local head = thief.Character and thief.Character:FindFirstChild("Head") :: BasePart?
	if not humanoid or not root or not head then
		return
	end

	local ground = CFrame.new(head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, 0)) * root.CFrame.Rotation
	local model = PlushieFactory.Build(entry.Id, entry.Mutation, "Carry", ground)
	if not model then
		return
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	model.Parent = carriedFolder

	base.Stealing[slot] = thief
	BaseService:RenderSlot(owner, slot)

	local carry: Carry = { Owner = owner, Slot = slot, Entry = entry, Model = model }
	carry.DiedConnection = humanoid.Died:Connect(function()
		self:Drop(thief, "died")
	end)
	carries[thief] = carry

	humanoid.WalkSpeed = Config.Steal.CarryWalkSpeed
	thief:SetAttribute("Carrying", Plushies.DisplayName(entry.Id, entry.Mutation))

	local name = Plushies.DisplayName(entry.Id, entry.Mutation)
	notify:FireClient(thief, `You grabbed {name}! Run back to your base!`, "success")
	notify:FireClient(owner, `⚠️ {thief.DisplayName} is stealing your {name}! Bonk them or touch them!`, "alert")
end

function StealService:_cleanup(thief: Player)
	local carry = carries[thief]
	if not carry then
		return
	end
	carries[thief] = nil
	if carry.DiedConnection then
		carry.DiedConnection:Disconnect()
	end
	carry.Model:Destroy()
	thief:SetAttribute("Carrying", nil)
	local humanoid = aliveParts(thief)
	if humanoid then
		humanoid.WalkSpeed = Services.MonetizationService:GetWalkSpeed(thief)
	end
end

-- Cancels a steal and sends the plushie back to its owner's pedestal.
function StealService:Drop(thief: Player, reason: string?)
	local carry = carries[thief]
	if not carry then
		return
	end
	local owner = carry.Owner
	self:_cleanup(thief)
	local base = BaseService:GetBase(owner)
	if base and base.Stealing[carry.Slot] == thief then
		base.Stealing[carry.Slot] = nil
		BaseService:RenderSlot(owner, carry.Slot)
	end
	if reason and thief.Parent then
		notify:FireClient(thief, `You dropped it ({reason}). It went back home.`, "error")
	end
	if owner.Parent and reason ~= "owner rebirthed" then
		notify:FireClient(owner, `Your {Plushies.DisplayName(carry.Entry.Id, carry.Entry.Mutation)} is safe again!`, "success")
	end
end

function StealService:_complete(thief: Player)
	local carry = carries[thief]
	if not carry then
		return
	end
	local owner = carry.Owner
	-- Make sure the owner still has exactly this plushie in that slot.
	local current = BaseService:GetEntry(owner, carry.Slot)
	if current ~= carry.Entry then
		self:Drop(thief, nil)
		return
	end
	if not BaseService:FindFreeSlot(thief) then
		self:Drop(thief, "your base is full")
		return
	end
	self:_cleanup(thief)
	local entry = BaseService:RemovePlushie(owner, carry.Slot)
	if not entry then
		return
	end
	BaseService:AddPlushie(thief, entry.Id, entry.Mutation)

	local data = Services.DataService:Get(thief)
	if data then
		data.Steals += 1
	end
	Services.EconomyService:RefreshStats(thief)

	local name = Plushies.DisplayName(entry.Id, entry.Mutation)
	notify:FireClient(thief, `You stole {name}! 😈`, "success")
	notify:FireClient(owner, `{thief.DisplayName} stole your {name}! Lock your base next time 🔒`, "alert")
	local def = Plushies.Get(entry.Id)
	if Config.Conveyor.AnnounceRarities[def.Rarity] then
		announce:FireAllClients(`{thief.DisplayName} STOLE {owner.DisplayName}'s {name}!`, Plushies.GetRarity(def.Rarity).Color)
	end
end

function StealService:CancelAllFor(player: Player)
	self:Drop(player, nil)
	for thief, carry in carries do
		if carry.Owner == player then
			self:Drop(thief, "owner rebirthed")
		end
	end
end

function StealService:Start()
	while true do
		task.wait(0.1)
		for thief, carry in carries do
			local _, root = aliveParts(thief)
			if not root or not thief.Parent then
				self:Drop(thief, "died")
				continue
			end
			local owner = carry.Owner
			if not owner.Parent or not BaseService:GetBase(owner) then
				self:_cleanup(thief)
				continue
			end
			local _, ownerRoot = aliveParts(owner)
			if ownerRoot and (ownerRoot.Position - root.Position).Magnitude <= Config.Steal.OwnerTagDistance then
				self:Drop(thief, `{owner.DisplayName} tagged you`)
				continue
			end
			if BaseService:IsInOwnBase(thief) then
				self:_complete(thief)
			end
		end
	end
end

function StealService:OnPlayerRemoving(player: Player)
	self:CancelAllFor(player)
end

return StealService
