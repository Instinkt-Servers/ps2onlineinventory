--Pointshop2 remove item. (You need to call with the item name as it displays in the menu e.g. "Top Hat")
--Returns true if item was removed successfully, false if not
local Player = FindMetaTable( "Player" )
function Player:PS2_EasyRemoveItem( displayName )
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