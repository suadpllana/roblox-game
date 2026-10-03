-- Client entry point: builds the UI and hooks up server messages.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local UI = script.Parent:WaitForChild("UI")
local Effects = require(UI.Effects)
local Hud = require(UI.Hud)
local Notifications = require(UI.Notifications)
local Popups = require(UI.Popups)
local Shop = require(UI.Shop)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "GameUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

Notifications.Init(gui)
Shop.Init(gui)
Popups.Init(gui)
Hud.Init(gui)
Effects.Init()

Remotes.Get("Notify").OnClientEvent:Connect(function(text: string, kind: string?)
	Notifications.Toast(text, kind)
end)
Remotes.Get("Announce").OnClientEvent:Connect(function(text: string, color: Color3?)
	Notifications.Announce(text, color)
end)
