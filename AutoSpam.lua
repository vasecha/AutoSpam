
AUS_Frame = nil
AUS_SpamFrame = nil
AUS_Time = nil
AUS_LastTime = nil

function AUS_SplitString(s,t)
	local l = {n=0}
	local f = function (s)
		l.n = l.n + 1
		l[l.n] = s
	end
	local p = "%s*(.-)%s*"..t.."%s*"
	s = string.gsub(s,"^%s+","")
	s = string.gsub(s,"%s+$","")
	s = string.gsub(s,p,f)
	l.n = l.n + 1
	l[l.n] = string.gsub(s,"(%s%s*)$","")
	return l
end

function AUS_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("AutoSpam: " .. msg)
end

SLASH_AUTOSPAM1, SLASH_AUTOSPAM2 = '/aus', '/autospam'
function SlashCmdList.AUTOSPAM(msg, editbox)

	local vars = AUS_SplitString(msg, " ")
	for k,v in vars do
		if v == "" then
			v = nil
		end
	end
	local cmd, arg = vars[1], vars[2]

	if (cmd == "list") then
		if (table.getn(AUS_Global.Messages) == 0) then
			AUS_Print("No messages.")
		else 
			for num, mesg in AUS_Global.Messages do
				AUS_Print(
					"#" .. num .. ": [" .. (mesg.ChatType or "")
						.. "][" .. (mesg.Channel or "")
						.. "] " .. mesg.Text)
			end
		end
	elseif (cmd == "add") then
		local index = table.getn(AUS_Global.Messages) + 1
		AUS_Global.Messages[index] = {
			Text = arg,
			ChatType = "SAY",
			Channel = nil
		}
		AUS_Print("Added: #" .. index .. ": " .. arg)
	elseif (cmd == "del") then
		local index = tonumber(arg)
		local mesg = AUS_Global.Messages[index]
		if (mesg) then
			AUS_Print("Deleted: #" .. index .. ": " .. mesg.Text)
			AUS_Global.Messages[index] = nil
		else
			AUS_Print("No message with index #" .. index)
		end
	elseif (cmd == "clear") then
		AUS_Global.Messages = {}
		AUS_Print("All messages were deleted.")
		
	elseif (cmd == "status") then
		AUS_Print("Status: " .. (AUS_Global.Enabled and "ON" or "OFF"))
		AUS_Print("Time to next message: " .. AUS_Time)
	elseif (cmd == "timer") then
		if (arg) then
			AUS_Global.Interval = tonumber(arg)
		end
		AUS_Print("Time interval: "
			.. AUS_Global.Interval .. " seconds.")
	elseif (cmd == "on") then
		AUS_Enable()
		AUS_Print("Enabled.")
	elseif (cmd == "off") then
		AUS_Disable()
		AUS_Print("Disabled.")
	elseif (cmd == "spam") then
		AUS_DoSpam()
	else
		AUS_Print("Commands: list | add [text] | del [index] | clear | status | timer [number] | on | off | spam")
	end
end  

AUS_Frame = CreateFrame("frame")
AUS_Frame:RegisterEvent("ADDON_LOADED")
AUS_Frame:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" then
		if string.lower(arg1) == "autospam" then

			if not AUS_Global then
				AUS_Global = {
					Messages = {},
					Index = 0,
					Interval = 60,
					Enabled = false
				}
			end

			AUS_Setup()
		end
	end
end)

function AUS_Setup()
	AUS_Time = 0
	AUS_LastTime = 0

	AUS_SpamFrame = CreateFrame("frame")
end 

function AUS_Enable()
	AUS_Global.Enabled = true
	AUS_SpamFrame:SetScript("OnUpdate", AUS_Spam_Update)
end

function AUS_Disable()
	AUS_Global.Enabled = false
	AUS_SpamFrame:SetScript("OnUpdate", nil)
end

function AUS_Spam_Update()
	local elapsed = time() - AUS_LastTime
	AUS_LastTime = time()

	AUS_Time = AUS_Time - elapsed
	if (AUS_Time <= 0) then
		AUS_Time = AUS_Global.Interval
		AUS_DoSpam()
	end
end

function AUS_DoSpam()
	local size = table.getn(AUS_Global.Messages)
	if (size > 0) then
		local rand = math.random(1, size)
		local mesg = AUS_Global.Messages[rand]

		AUS_Print("Sending message...")
		SendChatMessage(mesg.Text, mesg.ChatType, nil, mesg.Channel)
	end
end
