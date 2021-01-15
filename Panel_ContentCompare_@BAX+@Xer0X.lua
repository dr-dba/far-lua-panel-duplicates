--[[
if true then return end --]]

--[[
Вариант группирования файлов по длине и CRC, обхода файлов одной панели и поиска на другой
"парных" (совпадающих по длине и CRC).
--]]
--[[
local F = far.Flags
local DialogTools = require"BAX.DialogTools"
local GetMsgEx = require"BAX.GetMsg"
-]]
local tin = table.insert
--[=[
Сравнение панелей по содержимому.
Выделяются файлы, копия которых (безотносительно к имени) имеется на другой панели
-- [[*D*]] local le = require("le")
----------------------------------------------------------------------------------
local function CmpDial()
	local DlgItems = {}
	local function Add(DItem) tin(DlgItems, DialogTools.DialogItem(DItem)) end
	local h, w = 13, 70
	Add {'DI_DOUBLEBOX',	x1 = 0, y1 = 0, x2 = w, y2 = h, text = 'Сравнение панелей'}
	Add {'DI_CHECKBOX',	x1 = 3, y1 = 2,			Text = 'При сравнении учитывать дату',		Checked = 0 }
	Add {'DI_CHECKBOX',	x1 = 3, y1 = 3,			Text = 'Выделить одинаковые файлы на панелях',	Checked = 1 }
	Add {'DI_TEXT',		x1 = 1, x2 = w - 2, y1 = 5,	Text = 'Выполнить сценарий для совпавших файлов:',	Flags = 'DIF_CENTERTEXT' }
	Add {'DI_TEXT',		x1 = 3, y1 = 6,			Text = 'Для файлов с активной  панели (%1 - имя файла)' }
	Add {'DI_EDIT',		x1 = 3, x2 = w - 4, y1 = 7 }
	Add {'DI_TEXT',		x1 = 3, y1 = 8,			Text = 'Для файлов с пассивной панели (%1 - имя файла)' }
	Add {'DI_EDIT',		x1 = 3, x2 = w - 4, y1 = 9 }
	Add {'DI_TEXT',		x1 = -1, y1 = 10,									Flags = 'DIF_SEPARATOR'}
	Add {'DI_BUTTON',	y1 = 11,			Text = 'Ok',						Flags = 'DIF_CENTERGROUP|DIF_DEFAULTBUTTON' }
	Add {'DI_BUTTON',	y1 = 11, 			Text = 'Cancel',					Flags = 'DIF_CENTERGROUP' }
	far.Dialog('44C0A2E9-5F23-4E5C-9BE9-D94F3849D63B', -1, -1, w, h, nil, DlgItems, F.FDLG_SMALLDIALOG)
end -- CmpDial
--]=]
-------------------------------------------------------------------------------------
local function CmpFunc()

	local function CreateListHashes(_Panel, WhatPanel, whatpanel, tbl_sizes)
		local Result = {}
		local res_status
		local Path = _Panel.Path..(_Panel.Path:sub(-1) == '\\' and '' or '\\')
		local i1 = 1
		local i2 = _Panel.Selected and _Panel.SelCount or _Panel.ItemCount
		local GetFun = _Panel.Selected and panel.GetSelectedPanelItem or panel.GetPanelItem
		for i = i1, i2 
		do
			if	false	
			and	mf.waitkey(1, 0) == 'Esc' 
			and	1 == far.Message('Вы действительно хотите прервать процесс сравнения файлов?', 'Сравнение панелей по содержимому', ';YesNo', 'w') 
			then	break
			end
			local	Item = GetFun(nil, whatpanel, i)
			if not	Item.FileAttributes:match("d")
			and	type(tbl_sizes[Item.FileSize]) == "table"
			then				
				local	FullName = Path..Item.FileName
				local	plgin_call_res = Plugin.SyncCall("E186306E-3B0D-48C1-9668-ED7CF64C0E65", "gethash", 'SHA-512', FullName, true)
				if	plgin_call_res == "userabort"
				then	res_status = plgin_call_res
					break
				end
				local sKey = ('%.10d;%s'):format(
					Item.FileSize,
				--	Item.FileSize == 0 and (' '):rep(128) or
					plgin_call_res or "<EMPTY>"
						)
				if Result[sKey] == nil then Result[sKey] = { } end
				tin(Result[sKey], Item.FileName)
			end
		end
		return Result, res_status
	end -- CreateList

	local function CreateList_Sizes(_Panel, WhatPanel, whatpanel)
		local Result = { }
		local res_status, FullName
		local Path = _Panel.Path..(_Panel.Path:sub(-1) == '\\' and '' or '\\')
		local i1 = 1
		local i2 = _Panel.Selected and _Panel.SelCount or _Panel.ItemCount
		local GetFun = _Panel.Selected and panel.GetSelectedPanelItem or panel.GetPanelItem
		for i = i1, i2 do
			local	Item = GetFun(nil, whatpanel, i)
			if not	Item.FileAttributes:match("d")
			then    FullName = Path..Item.FileName
				local tbl_size_group = Result[Item.FileSize]
				if	type(tbl_size_group) ~= "table"
				then	tbl_size_group = { }
					Result[Item.FileSize] = tbl_size_group
				end
				table.insert(tbl_size_group, FullName)
			end
		end
		return Result, res_status
	end -- CreateList

	local tStart = Far.UpTime

	local AList_Sizes, act_size_status
	local PList_Sizes, pas_size_status
	local AListHashes, act_hash_status
	local PListHashes, pas_hash_status
	AList_Sizes, act_size_status = CreateList_Sizes(APanel, 0, 1)
	PList_Sizes, pas_size_status = CreateList_Sizes(PPanel, 1, 0)
	AListHashes, act_hash_status = CreateListHashes(APanel, 0, 1, PList_Sizes)
	if act_hash_status == "userabort" then goto after_create_list end
	PListHashes, pas_hash_status = CreateListHashes(PPanel, 1, 0, AList_Sizes)
	if pas_hash_status == "userabort" then goto after_create_list end
	::after_create_list::
--	local ASelList, PSelList, KeyList = { }, { }, { }
	local ASelList, PSelList = { }, { }
	local i, v = next(AListHashes)
	while i do
		if PListHashes[i] then
		--	KeyList[i] = {v, PList[i]}
			for _, w in ipairs(v)		do	tin(ASelList, w) end
			for _, w in ipairs(PListHashes[i]) do	tin(PSelList, w) end
		end
		i, v = next(AListHashes, i)
	end
	if #ASelList > 0 then
		Panel.Select(0, 0)
		Panel.Select(1, 0)
		Panel.Select(0, 1, 2, table.concat(ASelList, '\n'))
		Panel.Select(1, 1, 2, table.concat(PSelList, '\n'))
		-- CmpDial()
	end
--	le({ Time = Far.UpTime - tStart, AList = AList, PList = PList, ASelList = ASelList, PSelList = PSelList }) --]]
end -- CmpFunc

MenuItem {
	description = "Сравнение панелей по содержимому",
	menu = "Plugins",
	area = "Shell",
	guid = "C95988A8-E802-4541-A2F3-323D8FA89A12",
	text = function(menu, area) return "&Compare by content (Сравнение панелей по содержимому)" end,
	action = function(OpenFrom, Item) CmpFunc() end
}

NoMacro { -- Для активации уберите 'No' в начале строки
	id = "748A9A2C-1D4B-4A85-9B27-B881F98BAC90",
	area = "Shell",
	key = "", -- Сюда свой хоткей вставить
	description = "Сравнение панелей по содержимому",
	flags = "",
	condition = function(key, data) return APanel.Visible and PPanel.Visible end,
	action = function(data) CmpFunc() end
}
