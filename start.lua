local discordia = require('discordia')
local client = discordia.Client()
local embeds = require('./embeds.lua')
local Logger = discordia.Logger
local Games = {};
local Players = {};
local Timer = require("Timer");

client:on('ready', function()
    
end)

local boarddata = require('./board.lua')
local Sets = boarddata.Sets
local Board = boarddata.Board
local Properties = boarddata.Properties
local Chance = boarddata.Chance
local Chest = boarddata.Chest

function move(playerid, moves, m1, m2)
local gameid = Players[playerid].Game
if Players[playerid].Position + moves > #Board then
local total = Players[playerid].Position + moves
print(Players[playerid].Position)
Players[playerid].Position = total-#Board
print(Players[playerid].Position)
else
Players[playerid].Position = Players[playerid].Position + moves
end
if m1 ~= m2 then
Players[playerid].isReady = false
print(Players[playerid])
print(Players[playerid].Order)
print(Players[playerid].Game)
print(Games[gameid])
print(Games[gameid].order)
print(#Games[gameid].order)
if Players[playerid].Order == #Games[gameid].order then

for i,v in pairs(Games[gameid].players) do
if Players[i].Order == 1 then
Players[i].isReady = true
Timer.setTimeout(50, function() Players[i].Player:send("It is your turn.") end)
end
end

else

for i,v in pairs(Games[gameid].players) do
if Players[i].Order == Players[playerid].Order + 1 then
Players[i].isReady = true
Timer.setTimeout(50, function() Players[i].Player:send("It is your turn.") end)
end
end

end
end

end

function announce(gameid, message)

for i,v in pairs(Games[gameid].players) do
Players[i].Player:send(message)
end
end

client:on('messageCreate', function(message)
	local commandran = false
	if string.sub(message.content,1,8) == "mb:make " then
		commandran = true
		local id = string.sub(message.content,9)
		if id ~= "" then
			if not Players[message.author.id] then
				if not Games[id] then
					local playerdata = {};
					playerdata.Player = message.author
					playerdata.ID = message.author.id
					playerdata.Username = message.author.username
					playerdata.Cash = 1500
					playerdata.Game = id
					playerdata.Order = 1
					playerdata.Leader = true
					playerdata.Position = 0
					Players[message.author.id] = playerdata
					local gamedata = {};
					gamedata.players = {}
					gamedata.order = {};
					gamedata.order[1] = message.author.id
					gamedata.players[message.author.id] = playerdata
					gamedata.ID = id
					gamedata.started = false;
					Games[id] = gamedata
					message:reply("Game created.")
				else
					message:reply("That ID is already being used")
				end
			else
				message:reply("You're already in a game.")
			end
		else
			message:reply("I require a game ID")
		end
	elseif string.sub(message.content,1,8) == "mb:join " then
		commandran = true
		local id = string.sub(message.content,9)
		if id ~= "" then
			if not Players[message.author.id] then
				if Games[id] and Games[id].started == false then
					local playerdata = {};
					playerdata.Player = message.author
					playerdata.ID = message.author.id
					playerdata.Username = message.author.username
					playerdata.Cash = 1500
					playerdata.Game = id
					playerdata.Order = #Games[id].order+1
					playerdata.Leader = false
					Players[message.author.id] = playerdata
					Games[id].players[message.author.id] = playerdata
					Games[id].order[#Games[id].order+1] = message.author.id
					message:reply("Added you to the game")
				else
					message:reply("That game doesn't exist or has already started.")
				end
			else
				message:reply("You're already in a game")
			end
		else
			message:reply("I require a game ID")
		end
	end
	if commandran == false then
	if message.guild == nil then
	if message.content == "mb:stats" then
		if Players[message.author.id] then
			local playerdata = Players[message.author.id]
			local embed = embeds.create("Game Details", 1146986)
			embeds.field(embed, "Game ID", playerdata.Game, true)
			embeds.field(embed, "Cash", playerdata.Cash.."$", true)
			message.channel:send({embed=embed})
		else
			message:reply("You're not in a game...")
		end
	elseif message.content == "mb:chest" then
		announce(Players[message.author.id].Game, Chest[ math.random( 0, #Chest - 1 ) ])
	elseif message.content == "mb:chance" then
		announce(Players[message.author.id].Game, Chance[ math.random( 0, #Chance - 1 ) ])		
	elseif message.content == "mb:start" then
		if Players[message.author.id] then
			if Players[message.author.id].Leader == true then
				Games[Players[message.author.id].Game].started = true;
				for i,v in pairs(Games[Players[message.author.id].Game].players) do
					Players[i].Position = 1
				end
				Players[message.author.id].isReady = true
				announce(Players[message.author.id].Game, "The game has started.")
				Players[message.author.id].Player:send("It is your turn.")
			else
				message:reply("You're not the game's leader.")
			end
		else
			message:reply("You're not in a game...")
		end
	elseif string.sub(message.content, 1, 8) == "mb:chat " then
		announce(Players[message.author.id].Game, message.author.username.."("..message.author.id.."): "..string.sub(message.content, 9))
	elseif string.sub(message.content, 1, 8) == "mb:info " then
		for i,v in pairs(Properties) do
			if v.name == string.sub(message.content, 9) then
				local owner;
				if v.owner then
					owner = Players[v.owner].Username
				else
					owner = "Nobody"
				end
				local embed = embeds.create("Property Info")
				embed.description = "Information for card: "..v.name
				embeds.field(embed, "Owned by", owner)
				embeds.field(embed, "Price", v.price)
				embeds.field(embed, "Rent", v.cost)
				message.channel:send({embed=embed})
			end
		end
	elseif string.sub(message.content, 1,7) == "mb:add " then
		if tonumber(string.sub(message.content, 8)) then
			Players[message.author.id].Cash = Players[message.author.id].Cash + tonumber(string.sub(message.content, 8))
			announce(Players[message.author.id].Game, message.author.username.." has taken $"..string.sub(message.content, 8))
		end
	elseif string.sub(message.content,1, 8) == "mb:move " then
		for i,v in pairs(Board) do
			if v.name == string.sub(message.content,9) then
				Players[message.author.id].Position = i
				announce(Players[message.author.id].Game, message.author.username.." has moved to: "..v.name)
			end
		end
	elseif string.sub(message.content,1,8) == "mb:getp " then
		for i,v in pairs(Properties) do
			if v.name == string.sub(message.content,9) and v.owner == nil then
				v.owner = message.author.id
				announce(Players[message.author.id].Game, message.author.username.." has claimed "..v.name)
			end
		end
	elseif string.sub(message.content, 1,7) == "mb:rem " then
                if tonumber(string.sub(message.content, 8)) then
                        Players[message.author.id].Cash = Players[message.author.id].Cash - tonumber(string.sub(message.content, 8))
			announce(Players[message.author.id].Game, message.author.username.." has removed $"..string.sub(message.content, 8))
                end
	elseif message.content == "mb:end" then
                if Players[message.author.id] then
                        if Players[message.author.id].Leader == true then
				local id = Players[message.author.id].Game
                                for i,v in pairs(Games[id].players) do
					Players[i]=nil;
				end
				Games[id]=nil;
                        else
                                message:reply("You're not the game's leader.")
                        end
                else
                        message:reply("You're not in a game...")
                end
        elseif message.content == "mb:roll" then
		if Players[message.author.id] and Players[message.author.id].isReady == true then
			local roll1 = math.random(1,6)
			local roll2 = math.random(1,6)
			local roll = roll1 + roll2
			local footertext = tostring(roll1.." + "..roll2.." = "..roll)
			local embed = embeds.create(Players[message.author.id].Username.." rolled a "..roll.."...")
			embed.footer = {text=footertext}
			move(message.author.id, roll, roll1, roll2)
			embed.description = "...which means they landed on: "..Board[Players[message.author.id].Position].name
			local prop = Properties[Board[Players[message.author.id].Position].id]
			local owner = "";
			if prop and prop.owner then
				owner = Players[prop.owner].Username
			else
				owner = "Nobody"
			end
			--local owner = Players[Properties[Board[Players[message.author.id].Position].id].owner].username or "Nobody"
			embeds.field(embed, "Owner", owner)
			announce(Players[message.author.id].Game, {embed=embed})
		else
			message:reply("You're not in a game, or it's not your turn.")
		end
	end
	end
	end
end)

client:run('Bot MzUxMzYwODI4MDQ3MzYwMDAx.DIRdyA.pT1CtRN8yoa4OK8vuwpJxd3uDWU')

