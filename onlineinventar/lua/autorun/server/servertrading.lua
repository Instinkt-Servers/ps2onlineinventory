--[[
    Config
--]]
local db_host = "127.0.0.1"
local db_name = "username"
local db_username = "username"
local db_pw = "password"
local db_port = 3306
local delay = 10
local delay2 = 10
local lastOccurance = -delay
local lastOccurance2 = -delay
 
local trade_chatcommand = "!trade" -- what to type in chat to trade item
local get_chatcommand = "!get" -- what to type in chat to get item
local list_chatcommand = "!list" -- what to type in chat to list items
local trade_blacklist = { -- items that cant be traded
    ["Hatchet"] = true,
	["Jumppack"] = true,
	["Jump Pack"] = true,
	["Stattrak Modul"] = true,
	["2000 Donatorpunkte"] = true,
	["2000 Donatorpunkte für Ostern"] = true,
	["Stattrak Modul"] = true,
    ["6000 Premium Punkte"] = true
}
local lua_netstring = "crosstrade.luarun" -- netstring used for client chat manipulation
local chat_prefix = [[chat.AddText(Color(128,128,128),"[Instinkt´s Cross Trading] ",%s)]] -- chat prefix
local chat_texts = { 
    [[Color(222,222,222),"Du hast folgendes Item gehandelt: ",Color(222,222,0),"%s",Color(222,222,222),"."]],
    [[Color(222,222,222),"Item ",Color(222,222,0),"%s",Color(222,222,222)," existiert nicht."]],
    [[Color(222,222,222),"Item ",Color(222,222,0),"%s",Color(222,222,222)," kann nicht gehandelt werden."]],
    [[Color(222,222,222),"You don't have ",Color(222,222,0),"%s",Color(222,222,222)," in your Pointshop inventory."]],
    [[Color(222,222,222),"Du hast etwas ungütliges eingetippt."]],
    [[Color(222,222,222),"Es gab ein Problem mit der Datenbank. Handel abgebrochen."]],
    [[Color(222,222,222),"Du hast ",Color(222,222,0),"%s",Color(222,222,222)," nicht in deinem Online - Inventar."]],
    [[Color(222,222,222),"Dein Pointshop Inventar ist voll!"]],
    [[Color(222,222,222),"Du hast ",Color(222,222,0),"%s",Color(222,222,222)," in dein Pointshop Inventar erhalten."]],
    [[Color(222,222,222),"Du hast ",Color(222,222,0),"%s",Color(222,222,222)," in dein Pointshop Inventar erhalten, (",Color(222,222,0),"%i",Color(222,222,222),") noch im Inventar."]],
    [[Color(222,222,222),"Du hast bisher noch nichts gehandelt."]],
    [[Color(222,222,222),"Deine Items in Inventar: -"]],
    [[Color(222,222,0),"%s ",Color(222,222,222),"(",Color(222,222,0),"%i",Color(222,222,222),")."]]
}
local enabled_ascii_chars = { -- enabled ascii chars for items, prevents exploits (WARNING HARDCODED)
    [32] = true,[48] = true,[49] = true,[50] = true,[51] = true,[52] = true,[53] = true,[54] = true,[55] = true,[56] = true,[57] = true,[65] = true,[66] = true,[67] = true,[68] = true,[69] = true,[70] = true,[71] = true,[72] = true,[73] = true,[74] = true,[75] = true,[76] = true,[77] = true,[78] = true,[79] = true,[80] = true,[81] = true,[82] = true,[83] = true,[84] = true,[85] = true,[86] = true,[87] = true,[88] = true,[89] = true,[90] = true,[97] = true,[98] = true,[99] = true,[100] = true,[101] = true,[102] = true,[103] = true,[104] = true,[105] = true,[106] = true,[107] = true,[108] = true,[109] = true,[110] = true,[111] = true,[112] = true,[113] = true,[114] = true,[115] = true,[116] = true,[117] = true,[118] = true,[119] = true,[120] = true,[121] = true,[122] = true
}
--[[
    Config
--]]
 
--[[
    The code itself
--]]
require("mysqloo")
util.AddNetworkString(lua_netstring)
 
crosstrade = crosstrade or {}
crosstrade.connect_to_mysql = function()
    crosstrade.db = mysqloo.connect(db_host,db_username,db_pw,db_name,db_port)
    function crosstrade.db.onConnected() crosstrade:ConsolePrint(Color(0,222,0),"MySQL connected successfully.\n") end
    function crosstrade.db.onConnectionFailed(q,err) crosstrade:ConsolePrint(Color(222,0,0),"MySQL connection error "..err..".\n") end
    crosstrade.db:connect()
end
 
hook.Add("Initialize","crosstrade.mysql_connect",function()
    crosstrade.connect_to_mysql()
end)
 
concommand.Add("crosstrade_mysql_reconnect",function(ply)
    if not ply:IsAdmin() or not ply:IsSuperAdmin() then return end
    crosstrade.connect_to_mysql()
end)
 
local ply_meta = FindMetaTable( "Player" )
 
function ply_meta:PS2_EasyRemoveItem(displayName)
    local itemClass
    for _, class in pairs(KInventory.Items) do
        if class.PrintName and string.lower(class.PrintName) == string.lower(displayName) then
            itemClass = class.className
            break
        end
    end      
    if not itemClass then Promise.Reject( 1, "Cant't remove item. Item does not exist: "..displayName ) return false end
 
    local items = self.PS2_Inventory:getItems()
 
    local item
    for k,v in pairs(items) do
        if (tonumber(v.class.className) == tonumber(itemClass)) then print(item) item = v break end
    end
 
    if not item then Promise.Reject( 1, string.format("Can't remove %s from %s (%s). They don't have any of this item.",displayName,self:Nick(),self:SteamID())) return false end
    local def
    if self.PS2_Inventory:containsItem( item ) then
        def = self.PS2_Inventory:removeItem( item )
    end
   
    def:Then( function( )
        item:OnHolster( )
        item:OnSold( )
    end )
    :Then( function( )
        KInventory.ITEMS[item.id] = nil
        return item:remove( )
    end )
    return true
end
 
function crosstrade:HasItemInPS2Inventory(ply,item_name)
    local inv = ply.PS2_Inventory:getItems()
    local itemclass
 
    for k,v in pairs(Pointshop2.GetRegisteredItems()) do
        if v.PrintName and string.lower(v.PrintName) == string.lower(item_name) then
            itemclass = v.className
            break
        end
    end
 
    for k,v in pairs(inv) do
        if (tonumber(v.class.className) == tonumber(itemclass)) then
            return true
        end
    end
 
    return false
end
 
function crosstrade:PrettyPrintName(item_name)
    for k,v in pairs(Pointshop2.GetRegisteredItems()) do
        if v.PrintName and string.lower(v.PrintName) == string.lower(item_name) then
            return v.PrintName
        end
    end
 
    return false
end
 
function crosstrade:ConsolePrint(...)
    MsgC(Color(128,128,128),"[Instinkt Servers Cross Trading] ",...)
end
 
function crosstrade:SendLuaEx(ply,code)
    net.Start(lua_netstring)
    net.WriteString(code)
    net.Send(ply)
end
 
function crosstrade:ItemExists(item_name)
    for k,v in pairs(Pointshop2.GetRegisteredItems()) do
        if v.PrintName and string.lower(v.PrintName) == string.lower(item_name) then
            return true
        end
    end
 
    return false
end
 
function crosstrade:GiveItemByName(ply,item_name)
    local classname
    for k,v in pairs(Pointshop2.GetRegisteredItems()) do
        if v.PrintName and string.lower(v.PrintName) == string.lower(item_name) then
            classname = v.className
            break
        end
    end
 
    return ply:PS2_EasyAddItem(classname)
end
 
function crosstrade:CheckForExploit(str)
    local pos = 0
    local stop_read = false
 
    repeat
        pos = pos + 1
        local currentchar_ascii = string.byte(str[pos],1,1)
 
        if not enabled_ascii_chars[currentchar_ascii] == true then
            stop_read = true
            return true
        end
 
        if pos == #str then
            stop_read = true
        end
    until stop_read
 
    return false
end
 
function crosstrade:CheckItemFromInventory(sid64,item_name)
    local query = crosstrade.db:query("SELECT * FROM Inventar WHERE steamid = '" .. sid64 .. "' AND item = '" .. item_name .. "'")
    return query
end
 
function crosstrade:RemoveTradeRow(sid64,item_name)
    local query = crosstrade.db:query("DELETE FROM Inventar WHERE steamid = '".. sid64 .."' AND item = '".. item_name .."'")
    return query
end
 
function crosstrade:AddItemMenge(sid64,item_name)
    local query = crosstrade.db:query("UPDATE Inventar SET menge = menge +1 WHERE steamid = '" .. sid64 .. "' AND item = '" .. item_name .. "'")
    return query
end
 
function crosstrade:RemoveItemMenge(sid64,item_name)
    local query = crosstrade.db:query("UPDATE Inventar SET menge = menge -1 WHERE steamid = '" .. sid64 .. "' AND item = '" .. item_name .. "'")
    return query
end
 
function crosstrade:InsertItemInInventory(nick,sid64,item_name)
    local query = crosstrade.db:query("INSERT INTO Inventar(name,steamid, item, server, menge) VALUES ('" .. nick .. "','" .. sid64 .. "', '" .. item_name .. "', " .. 0 .. ", " .. 1 .. ") ")
    return query
end
 
function crosstrade:GetAllItems(sid64)
    local query = crosstrade.db:query("SELECT * FROM Inventar WHERE steamid = '" .. sid64 .. "'")
    return query
end
 
hook.Add("PlayerInitialSpawn","crosstrade.sendluaex",function(ply)
    ply:SendLua(string.format([[net.Receive("%s",function() local str = net.ReadString() RunString(str,"crosstrade") end)]],lua_netstring))
end)
 
--local query1 = databaseObject:query("INSERT INTO Inventar(name,steamid, item, server, menge) VALUES ('" .. ply:GetName() .. "','" .. ply:SteamID64() .. "', '" .. ItemNum .. "', " .. 0 .. ", " .. 1 .. ") ")
--self:PS2_HasInventorySpace( 1 )
 
hook.Add("PlayerSay","crosstrade.tradecommand",function(ply,text)
    if string.sub(string.lower(text),1,#trade_chatcommand) == trade_chatcommand and text[#trade_chatcommand + 1] == " " then
		local item_name = string.sub(text,#trade_chatcommand + 2,#text)
        ply.lastgetCmd = ply.lastgetCmd or {}
        if ( ply.lastgetCmd[item_name] or 0 ) > CurTime() then
          ply:PrintMessage(HUD_PRINTTALK ,"[Instinkt Servers Cross Trading] Du musst etwas warten, bis Du wieder handeln kannst.")
        else
        if ply:Ping() > 500 then
          ply:PrintMessage(HUD_PRINTTALK ,"[Instinkt Servers Cross Trading] Dein Ping ist zu hoch, um das Online-Inventar nutzen zu können.")
        else
           
        local sid64 = ply:SteamID64()
        ply.lastgetCmd[item_name] = CurTime() + 10
 
        if crosstrade:CheckForExploit(item_name) == false then
            if crosstrade:ItemExists(item_name) == false then
                crosstrade:SendLuaEx(ply,string.format(chat_prefix,string.format(chat_texts[2],item_name)))
            else
                item_name = crosstrade:PrettyPrintName(item_name)
 
                if trade_blacklist[item_name] then
                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,string.format(chat_texts[3],item_name)))
                else
                    if crosstrade:HasItemInPS2Inventory(ply,item_name) == true then
                        local is_already_online = crosstrade:CheckItemFromInventory(sid64,item_name)
                        function is_already_online.onSuccess(q,data)
                            if data[1] == nil then
                                local insert_query = crosstrade:InsertItemInInventory(ply:Nick(),sid64,item_name)
                                function insert_query.onSuccess()
                                    ply:PS2_EasyRemoveItem(item_name)
                                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,string.format(chat_texts[1],item_name)))
                                end
                                function insert_query.onError()
                                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[6]))
                                end
 
                                insert_query:start()
                            else
                                local add_query = crosstrade:AddItemMenge(sid64,item_name)
                                function add_query.onSuccess()
                                    ply:PS2_EasyRemoveItem(item_name)
                                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,string.format(chat_texts[1],item_name)))
                                end
                                function add_query.onError(q,err)
                                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[6]))
                                end
 
                                add_query:start()
                            end
                        end
                        function is_already_online.onError(err)
                            crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[6]))
                        end
 
                        is_already_online:start()
                    else
                        crosstrade:SendLuaEx(ply,string.format(chat_prefix,string.format(chat_texts[4],item_name)))
                    end
                end
            end
        else
            crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[5]))
        end
       
        return ""
		end
    end
end
end)
 
hook.Add("PlayerSay","crosstrade.getcommand",function(ply,text)
    if string.sub(string.lower(text),1,#get_chatcommand) == get_chatcommand and text[#get_chatcommand + 1] == " " then
        local item_name = string.sub(text,#get_chatcommand + 2,#text)
        ply.lastgetCmd = ply.lastgetCmd or {}
		if ( ply.lastgetCmd[item_name] or 0 ) > CurTime() then
		  ply:PrintMessage(HUD_PRINTTALK ,"[Instinkt Servers Cross Trading] Du musst etwas warten, bis Du wieder handeln kannst.")
		else
		if ply:Ping() > 500 then
		  ply:PrintMessage(HUD_PRINTTALK ,"[Instinkt Servers Cross Trading] Dein Ping ist zu hoch, um das Online-Inventar nutzen zu können.")
		else
           
        local sid64 = ply:SteamID64()
        ply.lastgetCmd[item_name] = CurTime() + 10
        if crosstrade:CheckForExploit(item_name) == false then
            if crosstrade:ItemExists(item_name) == false then
                crosstrade:SendLuaEx(ply,string.format(chat_prefix,string.format(chat_texts[2],item_name)))
            else
                item_name = crosstrade:PrettyPrintName(item_name)
 
                local is_already_online = crosstrade:CheckItemFromInventory(sid64,item_name)
                function is_already_online.onSuccess(q,data)
                    if data[1] == nil then
                        crosstrade:SendLuaEx(ply,string.format(chat_prefix,string.format(chat_texts[7],item_name)))
                    else
                        if not ply:PS2_HasInventorySpace(1) then
                            crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[8]))
                        else
                            data = data[1]
 
                            if data["menge"] == 1 then
                                local removerow_query = crosstrade:RemoveTradeRow(sid64,item_name)
                                function removerow_query.onSuccess()
                                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,string.format(chat_texts[9],item_name)))
                                    crosstrade:GiveItemByName(ply,item_name)
                                end
                                function removerow_query.onError()
                                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[6]))
                                end
 
                                removerow_query:start()
                            elseif data["menge"] > 1 then
                                local decrease_query = crosstrade:RemoveItemMenge(sid64,item_name)
                                function decrease_query.onSuccess()
                                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,string.format(chat_texts[10],item_name,tonumber(data["menge"]) - 1)))
                                    crosstrade:GiveItemByName(ply,item_name)
                                end
                                function decrease_query.onError()
                                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[6]))
                                end
 
                                decrease_query:start()
                            end
                        end
                    end
                end
                function is_already_online.onError(err)
                    crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[6]))
                end
 
                is_already_online:start()
            end
        else
            crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[5]))
        end
       
        return ""
    end
	end
end
end)
 
hook.Add("PlayerSay","crosstrade.listcommand",function(ply,text)
    if string.sub(string.lower(text),1,#list_chatcommand) == list_chatcommand then
        local sid64 = ply:SteamID64()
        local item_name = "getallitems"
        ply.lastgetCmd = ply.lastgetCmd or {}
        if ( ply.lastgetCmd[item_name] or 0 ) > CurTime() then
          ply:PrintMessage(HUD_PRINTTALK ,"[Instinkt Servers Cross Trading] Du musst etwas warten, bis Du wieder handeln kannst.")
        else
        if ply:Ping() > 500 then
          ply:PrintMessage(HUD_PRINTTALK ,"[Instinkt Servers Cross Trading] Dein Ping ist zu hoch, um das Online-Inventar nutzen zu können.")
        else
           
        local sid64 = ply:SteamID64()
        ply.lastgetCmd[item_name] = CurTime() + 10
 
        local getall_query = crosstrade:GetAllItems(sid64)
        function getall_query.onSuccess(q,data)
            if data[1] == nil then
                crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[11]))
            else
                crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[12]))
 
                for k,v in pairs(data) do
                    crosstrade:SendLuaEx(ply,string.format([[chat.AddText(%s)]],string.format(chat_texts[13],v["item"],tonumber(v["menge"]))))
                end
            end
        end
        function getall_query.onError()
            crosstrade:SendLuaEx(ply,string.format(chat_prefix,chat_texts[6]))
        end
 
        getall_query:start()
 
        return ""
    end
end
end
end)
