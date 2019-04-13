local COMMON = require "libs.common"
local RX = require "libs.rx"
local STATE = require "world.state.state"
local PRINCIPLES = require "world.principles"
local Battle = require "world.battle"
local ENEMIES = require "world.enemies"

local TAG = "World"

local RESET_SAVE = true

---@class World:Observable
local M = COMMON.class("World")

function M:reset()
end

function M:initialize()
	self.PRINCIPLES = PRINCIPLES
	self.rx = RX.Subject()
	self.state = STATE
	self.autosave = true
	self.autosave_dt = 0
	self.autosave_time = 10
	self.battle = Battle()
	self.battle:set_world(self)
	self.battle:set_enemy(ENEMIES[1])
	self:reset()
end

function M:create_hero(race,class,alignment)
	assert(not self.state.hero)
	self.state:create_hero(race,class,alignment)
	self.battle:set_hero(self.state.hero.unit)
end

function M:update(dt)
	self.battle:update(dt)
	self:process_autosave(dt)
end

function M:process_autosave(dt)
	if self.autosave then
		self.autosave_dt = self.autosave_dt + dt
		if self.autosave_dt > self.autosave_time then
			self.autosave_dt = 0
			self:save()
		end
	end
end

---@param enemy EnemyUnit
function M:enemy_killed(enemy)
	self.state:add_gold(enemy.gold)
end

function M:save()
--	COMMON.i("save", TAG)
	local data = {state = self.state:save()}
	sys.save(sys.get_save_file("idle","data"), data)
end

function M:load()
	local data =  RESET_SAVE and {} or sys.load(sys.get_save_file("idle", "data"))
	if not data.state then return end
	self.state:load(data.state)
	self.battle:set_hero(self.state.hero.unit)
end

function M:dispose()
	self:reset()
end

return M()