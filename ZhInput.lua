--[[
Chinese Input Method for WoW
pure lua script , non-system-related
License is GPL v2  
My Blog (Chinese)  : http://www.seerhut.cn
Addon's Homepage   : http://www.seerhut.cn/zhinput
Homepage on SF.net : http://sourceforge.net/projects/zhinput/
On Curse Game      : http://www.curse.com/downloads/details/3230/
Email              : seerhut_AT_gmail_DOT_com

]]--
--------------------------------
-- GLOBAL VARS TO SAVE
INPUT_TYPE = 'pinyin'
SAVE_MEM = 'on'
STICKY_SEC = 0.15
HL_COLOR = '|cff00dddd'
--CHAT_ON = true
--MAIL_ON = true
--AUC_ON = true

--------------------------------
-- LOCAL VARS
local MY_DEBUG = nil
local VERSION = 'version 2.1 build 071204'
local G_PAGE = 1
local NEED_CLEAR_CAN = nil
local NEED_CLEAR_PY = nil
local NEED_DELETE_LAST_CHAR = nil
local IS_BS_PRESSED = nil
local TIME_NEED_BS = 0.0
local IS_LEFT_PRESSED = nil
local TIME_NEED_LEFT = 0.0
local IS_RIGHT_PRESSED = nil
local TIME_NEED_RIGHT = 0.0
local CAN_HL = 1  -- 1~~10
local cur_can = {}
local can_py = {}
local can_tail = 1
local page_tail = 0
local TB = {}; 
local chat_type = {"/r","/y","/s","/raid","/w","/bg","/g","/e","/macro","/p"} 
local HELP_MSG = 
[[/zhinput /zi    打开输入窗口
参数列表：
    about   插件信息
    help    此帮助信息
    open    打开输入窗口
    wubi    使用五笔输入
    pinyin  使用拼音输入(默认)
    savemem on   开启节省内存(默认)
    savemem off   关闭节省内存
    version   打印版本
IF YOU CANNOT SEE ANY CHINESE CHARACTERS, 
CHECK http://www.seerhut.cn/zhinput]]
local EDITBOX = ChatFrameEditBox
local mail_mode = nil
local auc_mode = nil
----------------------------------       
       
local function ziprint(msg)
    DEFAULT_CHAT_FRAME:AddMessage("ZhInput: "..msg, 0.0, 0.9, 0.9)
end

function ZhInput_Command(msg)
    if(msg=="") then
        ZhInput_Show()
    elseif(msg=="open") then
        ZhInput_Show()
    elseif(msg=="about") then
        Help:Show()  
    elseif(msg=="wubi") then
        INPUT_TYPE = 'wubi'
        ReloadTable()
    elseif(msg=="pinyin") then
        INPUT_TYPE = 'pinyin'
        ReloadTable()
    elseif(msg=="savemem on") then
        SAVE_MEM = 'on'
        ziprint("进入节省内存模式")
    elseif(msg=="savemem off") then
        SAVE_MEM = 'off'
        ziprint("离开节省内存模式（需重新进入游戏）")
    elseif(msg=="help") then
       ziprint(HELP_MSG)
       Help:Show()
    elseif(msg=="version") then
       ziprint(VERSION)
    else
    	ziprint(HELP_MSG)
    end
end

function ZhInput_OnLoad()
    ziprint("中文输入法启动 enjoy ^_^")
    ziprint("Use \"/zhinput\" or \"/zi\" to open input window  ")
    
    SlashCmdList["ZHOPEN"] = ZhInput_Command
    SLASH_ZHOPEN1 = "/zhinput"
    SLASH_ZHOPEN2 = "/zi"
    this:RegisterEvent("MAIL_SHOW")
    this:RegisterEvent("MAIL_CLOSED")
    this:RegisterEvent("AUCTION_HOUSE_SHOW")
    this:RegisterEvent("AUCTION_HOUSE_CLOSED")
end

function ZhInput_Show()
	
    if ZhInput:IsShown()  then return end
    
	if ( ChatFrameEditBox:IsVisible() or EDITBOX == ChatFrameEditBox )
		and not auc_mode and not mail_mode then
		EDITBOX = ChatFrameEditBox
		ChatFrameEditBox:Show() 
	elseif MailFrame:IsVisible()  then
		mail_mode = true
		if SendMailNameEditBox:IsVisible()  then
			EDITBOX = SendMailNameEditBox
		end
	elseif AuctionFrame ~= nil and AuctionFrame:IsVisible() then
		auc_mode = true
		if BrowseName:IsVisible()  then
			EDITBOX = BrowseName
		end
	end
    ZhInput:Show()
    CanArea:Show()
    PyArea:Show()
    --EDITBOX:SetText("")
    PyArea:SetFocus()
    if(INPUT_TYPE=="pinyin") then
    	InputType:SetText("拼音")
    elseif(INPUT_TYPE=="wubi") then
    	InputType:SetText("五笔")
    end
    
end


function ZhInput_GetFocus()
    PyArea:SetFocus()
end

function ZhInput_OnShow()

end

function Clear_Can()
	
    CanArea:SetText("")
    InfoArea:SetText("")
    G_PAGE = 1
    CAN_HL = 1
    cur_can = {}
	can_py = {}
	can_tail = 1
	page_tail = 0
	
end

function Clear_Py()
	
    PyArea:SetText("");
    Clear_Can()
    
end

function ZhInput_Reset()
    Clear_Py()
    Clear_Can();
    Help:Hide();

end

function ZhInput_Close()
-- 关闭zhinput 将焦点交给输入框
	
    ZhInput_Reset();
    ZhInput:Hide()
    Help:Hide()
    Control:Hide()
    Config:Hide()
    ReloadWarning:Hide()
	EDITBOX:SetFocus()
--     ChatFrameEditBox:Hide()
	
end

function ZhInput_OnEvent(event)
    if(event=="VARIABLES_LOADED") then 
        ReloadTable()
    elseif(event=="MAIL_SHOW") then 
        mail_mode = true
        EDITBOX = SendMailNameEditBox
        ZhInput_Show()
        
    elseif(event=="MAIL_CLOSED") then 
        mail_mode = nil
        ZhInput_Close()
        EDITBOX = ChatFrameEditBox
        
    elseif(event=="AUCTION_HOUSE_SHOW") then 
        auc_mode = true
        EDITBOX = BrowseName
        ZhInput_Show()
        
    elseif(event=="AUCTION_HOUSE_CLOSED") then 
        auc_mode = nil
        ZhInput_Close()
        EDITBOX = ChatFrameEditBox
    end
end

function ZhInput_OnKeyUp()
	if ( arg1 == 'BACKSPACE' )then
        IS_BS_PRESSED = nil
        TIME_NEED_BS = 0.0
        return
    end
    
    if ( arg1 == 'LEFT' )then
        IS_LEFT_PRESSED = nil
        TIME_NEED_LEFT = 0.0
        return
    end
    
    if ( arg1 == 'RIGHT' )then
        IS_RIGHT_PRESSED = nil
        TIME_NEED_RIGHT = 0.0
        return
    end
end

function ZhInput_OnKeyDown()
    --ziprint(arg1)
    if  ( arg1 == 'PRINTSCREEN' ) then
        Screenshot()
        return
    end
    if ( arg1 == 'ENTER' ) then
        PyArea_OnEnterPressed()
        return
    end
    if ( arg1 == 'BACKSPACE' )then
    	IS_BS_PRESSED = true
        PyArea_OnBackspacePressed()
        TIME_NEED_BS = GetTime()+STICKY_SEC
        return
    end
    if ( arg1 == 'SPACE' ) then
        PyArea_OnSpacePressed()
        return
    end
    if ( arg1 == 'ESCAPE' ) then
        PyArea_OnEscapePressed(ZhInput)
        return
    end
    if ( arg1 == 'PAGEUP' ) or (arg1 == 'UP')  then 
    	if  G_PAGE > 1 then
        	G_PAGE = G_PAGE-1
        	List_Can()
        end
        return
    end
    if ( arg1 == 'PAGEDOWN' ) or (arg1 == 'DOWN')  then 
    	if cur_can[G_PAGE*10+1] ~= nil then
        	G_PAGE = G_PAGE+1
        	List_Can()
        end
        return
    end
    
    if ( arg1 == 'HOME' ) and (cur_can ~= nil) then
    	CAN_HL = 1 
    	return
    end
    
    if ( arg1 == 'END' ) and (cur_can ~= nil) then
    	CAN_HL = can_tail
    	return 
    end
    
    if ( arg1 == 'LEFT' ) and (cur_can ~= nil) then 
    	IS_LEFT_PRESSED = true
        PyArea_OnLeftPressed()
        TIME_NEED_LEFT = GetTime()+STICKY_SEC
        return
    end
    
    if ( arg1 == 'RIGHT' ) and (cur_can ~= nil) then 
    	IS_RIGHT_PRESSED = true
    	PyArea_OnRightPressed()
    	TIME_NEED_RIGHT = GetTime()+STICKY_SEC
    	return
    end
    -- num key down
    
    text = PyArea:GetText()
    if (arg1 == '0' or arg1 == '1'  or arg1 == '2' or arg1 == '3' 
    or arg1 == '4' or arg1 == '5' or arg1 == '6' or arg1 == '7' 
    or arg1 == '8' or arg1 == '9') and ( cur_can ~= nil ) and not IsShiftKeyDown()  then 
        if arg1 == '0' then
            num = (G_PAGE-1)*10+10
        else
            num = (G_PAGE-1)*10+arg1
        end
        
        if  cur_can[num] ~= nil then 
            EDITBOX:Insert(cur_can[num])
            text = string.sub(text,1+string.len(can_py[num]),-1)
            PyArea:SetText(text)
			NEED_CLEAR_CAN = true
			NEED_DELETE_LAST_CHAR = true
        end
        return
     end
end 

function PyArea_OnUpdate()
-- 系统刷新界面
     text = PyArea:GetText() 
     
    if NEED_CLEAR_CAN  then
        Clear_Can()
        NEED_CLEAR_CAN = nil
       
    end
    if NEED_CLEAR_PY  then
        Clear_Py()
        NEED_CLEAR_PY = nil
       
    end
	if NEED_DELETE_LAST_CHAR  then
		PyArea:SetText(Delete_Last_Char(text))
		NEED_DELETE_LAST_CHAR = nil 
		
	end
    if IS_BS_PRESSED  then 
    	time = GetTime()
    	if time > TIME_NEED_BS then
    		PyArea_OnBackspacePressed()
    		TIME_NEED_BS = TIME_NEED_BS+STICKY_SEC
    	end
    end
    if IS_LEFT_PRESSED  then 
    	time = GetTime()
    	if time > TIME_NEED_LEFT then
    		PyArea_OnLeftPressed()
    		TIME_NEED_LEFT = TIME_NEED_LEFT+STICKY_SEC
    	end
    end
    if IS_RIGHT_PRESSED then 
    	time = GetTime()
    	if time > TIME_NEED_RIGHT then
    		PyArea_OnRightPressed()
    		TIME_NEED_RIGHT = TIME_NEED_RIGHT+STICKY_SEC
    	end
    end
    Highlight_Can()
end

function PyArea_OnLeftPressed()
-- 左箭头选择高亮候选词
	if cur_can == {} then return end
    if CAN_HL == 1 then 
    	if G_PAGE == 1 then --在首页第一个
    		CAN_HL = can_tail
    	else	  -- 在非首页第一个
    		CAN_HL = 10
    		G_PAGE = G_PAGE -1
    		List_Can()
    	end
    else 		--不在第一个
    	CAN_HL = CAN_HL - 1
    end
    
end

function PyArea_OnRightPressed()
-- 右箭头选择高亮候选词
	if cur_can == {} then return end 
    
	if G_PAGE == page_tail then --在末页(很可能候选词个数不是10！！！)
		if CAN_HL == can_tail then  --在最后
			CAN_HL = 1
			G_PAGE = 1
			List_Can()
		else 
			CAN_HL = CAN_HL +1
		end
	else	  -- 在非末页
		if CAN_HL == 10 then
			CAN_HL = 1
			G_PAGE = G_PAGE +1
			List_Can()
		else
			CAN_HL = CAN_HL +1
		end
	end
    
   
end

function PyArea_OnEnterPressed()
--   回车时把英文字符送入对话栏，并重置中文输入框,如果回车时拼音栏内没有字符，则送出消息
    
    if ( PyArea:GetText() == "" ) then -- 特殊情况
	    if mail_mode == true then
	    	if EDITBOX == SendMailNameEditBox then
	    		EDITBOX = SendMailSubjectEditBox
	    		PyArea:SetFocus()
	    	elseif EDITBOX == SendMailSubjectEditBox then
	    		EDITBOX = SendMailBodyEditBox
	    		PyArea:SetFocus()
	    	end
	    	return
	    elseif auc_mode == true then
	    	BrowseSearchButton:Click()
	    	return
	    end
    SendText(addHistory)
	EDITBOX:SetText("")
    ZhInput_Reset()
    else
        EDITBOX:Insert(PyArea:GetText())
        ZhInput_Reset();
    end 
end

function PyArea_OnEscapePressed(frame)
--   按ESC时如果输入框有文字则清除，否则退出中文输入法
    if PyArea:GetText() == '' then 
        ZhInput_Close()
    else
        ZhInput_Reset()
    end
end

function PyArea_OnBackspacePressed()
--    退格时将删除拼音栏内最后一个字符，如果拼音输入框为空则删除系统对话栏中最后字符
    text =  PyArea:GetText()
    msgtext = EDITBOX:GetText()
    if text == '' then  
        if msgtext ~= '' then
            EDITBOX:SetText(Delete_Last_Char(msgtext))
        end
    else 
        PyArea:SetText(Delete_Last_Char(text))
    end
end

function PyArea_OnSpacePressed()
	text = PyArea:GetText()
	if (text == "") then  --拼音区无字符，直接送一个空格到目的地
		EDITBOX:Insert(" ")
		NEED_CLEAR_PY = true
		NEED_CLEAR_CAN = true
		return
	end
	text = strtrim(text)
    i = 1
	 
	while (chat_type[i] ~= nil) do  -- parse chat type 
		if (text == chat_type[i] ) then
			EDITBOX:Insert(text.." ")
			NEED_CLEAR_PY = true
			NEED_CLEAR_CAN = true
			
			return
		end
		i = i+1
	end
	num = (G_PAGE-1)*10 + CAN_HL
	word = cur_can[num]
    if  (cur_can ~= {}) and (word ~= nil) then    --有相应候选词时，送出高亮的候选词，并将最前面相应的拼音删去
            EDITBOX:Insert(word)
            text = string.sub(text,1+string.len(can_py[num]),-1)
            PyArea:SetText(text)
			NEED_CLEAR_CAN = true
			NEED_DELETE_LAST_CHAR =true
    end
end


function PyArea_OnTabPressed()
	if mail_mode == true then
		EditBox_HandleTabbing(SEND_MAIL_TAB_LIST);
	else
    	EDITBOX:SetFocus()
    end
end

function PyArea_OnTextChanged()
--    拼音输入框文字有变动时寻找相对应的汉字列表，并更新候选框
	
    Clear_Can()
    Get_Can()
    List_Can()
    
end

function PyArea_OnTextSet()
--  设置拼音框时往往删除了最后的字符，所以不用在这里再一次调用以获取候选词表了
end

function Highlight_Can()
--   将相应的候选词进行高亮，在update时调用
	
	if (cur_can == {} ) or ( PyArea:GetText() == nil ) 
						or (CanArea:GetText() == nil) then return end
	text = CanArea:GetText()
	text = string.gsub(text,"|r",'')
	text = string.gsub(text,HL_COLOR,'')
	
	if CAN_HL > can_tail then
        	CAN_HL = can_tail
    end
	if G_PAGE == page_tail then --末页
		if can_tail == CAN_HL then  --最后
			head = string.find(text,CAN_HL%10)
			tail = -1
			tmp3 = ''
		else     --非最后
			num = CAN_HL 
			head = string.find(text,num)
			tail = string.find(text,(num+1)%10) - 1
			tmp3 = string.sub(text,tail+1)
		end
		
	else       --非末页
		if CAN_HL == can_tail then 
			head = string.find(text,"0")
			tail = -1
			tmp3 = ''
		else 
			num = CAN_HL 
			head = string.find(text,num)
			tail = string.find(text,(num+1)%10) - 1  
			tmp3 = string.sub(text,tail+1)
		end 
	end
	tmp1 = string.sub(text,1,head-1)
	tmp2 = string.sub(text,head,tail)
	
	CanArea:SetText(tmp1..HL_COLOR..tmp2..'|r'..tmp3)
--	CanArea:HighlightText(head,tail) 
end

function Get_Can()
-- 找出可用的候选词，写入本地表中
	
	cur_can = {}
	can_py = {}
	i=1
	text = PyArea:GetText()
	text = strtrim(text)
    while (text ~= "") do
    	if ( TB[text] ~= nil ) then
			table.insert(cur_can, TB[text][i])
			table.insert(can_py,text) 
			i = i+1
			while ( TB[text][i] ~= nil ) do	
				table.insert(cur_can, TB[text][i])
				table.insert(can_py,text) 
				i = i+1
			end
    	end
    	text = string.sub(text,1,-2)
		i = 1
    end
    
    page_tail = math.floor((#cur_can+9)/10) 
    
end

function List_Can()
--    将本地表cur_can中的候选词列在候选字框中
	
    start = (G_PAGE-1)*10+1
    if ( cur_can ~= nil ) then
        if( cur_can[start] ~= nil ) then 
            cantext = ""
            can_tail = 10
            for i=1,10 do
                if ( cur_can[start+i-1] ~= nil ) then
                    cantext = cantext..math.fmod(i,10)..":"..cur_can[start+i-1]
                else
                	can_tail = i -1
                    break
                end
            end
            CanArea:SetText(cantext)
            InfoArea:SetText(G_PAGE..'/'..page_tail)
        else
            Clear_Can();
        end
    else
        Clear_Can();
    end
	
end

function Switch_InputType()
	if (INPUT_TYPE == 'pinyin') then 
		INPUT_TYPE = 'wubi'
		ReloadTable()
		InputType:SetText("五笔")
	elseif (INPUT_TYPE == 'wubi') then 
		INPUT_TYPE = 'pinyin'
		ReloadTable()
		InputType:SetText("拼音")
	end
	if SAVE_MEM == 'on' then
		-- popup warning window
		ReloadWarning:Show()
	end
end

function ReloadTable()
    if (INPUT_TYPE == 'pinyin') and (pytable ~= nil) then
        TB = pytable
        if SAVE_MEM  == 'on' then
 			pytable = nil
            wbtable = nil
        end
        ziprint('使用拼音输入法')
        return
    end
    if (INPUT_TYPE == 'wubi')  and (wbtable ~= nil) then
        TB = wbtable
        if SAVE_MEM  == 'on' then
            pytable = nil
            wbtable = nil
        end
        ziprint('使用五笔输入法')
        return
    end 
    
end

function OpenControl_OnClick()
    if Control:IsShown() == nil then
        Control:Show()
    else 
    	Control:Hide()
    end
end

function OpenHelp_OnClick()
    if Help:IsShown() == nil then
        Help:Show()
    else 
    	Help:Hide()
    end
end

function OpenConfig_OnClick()
    if Config:IsShown() == nil then
        Config:Show()
    else 
    	Config:Hide()
    end
end

function Delete_Last_Char(text)
--  !!!! UTF-8中中文为三字节 ASCII为一字节
    lastcharcode = string.byte(text,-1)
    if lastcharcode ~= nil then
        if lastcharcode >= 128 then
           return strsub(text,1,-4)
       else
           return strsub(text,1,-2)
       end
    end 
end

function SendText(addHistory)
--  发送消息，这个函数是从游戏系统包里抄来的 
--  see ChatFrame.lua line 2708 function ChatEdit_SendText(editBox, addHistory)
	
--	ChatEdit_ParseText(editBox, 1);

	local type = ChatFrameEditBox:GetAttribute("chatType");
	local text = ChatFrameEditBox:GetText();
	if ( strfind(text, "%s*[^%s]+") ) then
		if ( type == "WHISPER") then
			local target = ChatFrameEditBox:GetAttribute("tellTarget");
			ChatEdit_SetLastToldTarget(target);
			SendChatMessage(text, type, ChatFrameEditBox.language, target);
		elseif ( type == "CHANNEL") then
			SendChatMessage(text, type, ChatFrameEditBox.language, ChatFrameEditBox:GetAttribute("channelTarget"));
		else
			SendChatMessage(text, type, ChatFrameEditBox.language);
		end
		if ( addHistory ) then
			ChatEdit_AddHistory(editBox);
		end
	end
end

function int2str(int)


end

function Editbox_Control(type)
	if type == "chat" then 
		EDITBOX = ChatFrameEditBox
		ChatFrameEditBox:Show() 
		mail_mode = nil
		auc_mode = nil
	elseif type == "to" then 
		if SendMailNameEditBox ~= nil and SendMailNameEditBox:IsVisible()  then
			EDITBOX = SendMailNameEditBox
			mail_mode = true
			auc_mode = nil
			
		else 
			ziprint("写信界面未打开")
		end
	elseif type == "subject" then 
		if SendMailSubjectEditBox ~= nil and SendMailSubjectEditBox:IsVisible() then
			EDITBOX = SendMailSubjectEditBox
			mail_mode = true
			auc_mode = nil
			--EDITBOX:SetText("输入信件主题")
			--EDITBOX:HighlightText()
		else 
			ziprint("写信界面未打开")
		end
	elseif type == "body" then 
		if SendMailBodyEditBox ~= nil and SendMailBodyEditBox:IsVisible()  then
			EDITBOX = SendMailBodyEditBox
			mail_mode = true
			auc_mode = nil
			--EDITBOX:SetText("输入信件内容")
			--EDITBOX:HighlightText()
		else 
			ziprint("写信界面未打开")
		end
	elseif type == "auc" then 
		if AuctionFrame ~= nil and AuctionFrame:IsVisible() then
			if BrowseName~= nil and BrowseName:IsVisible() then
				EDITBOX = BrowseName
				auc_mode = true
				mail_mode = nil
				--EDITBOX:SetText("输入商品名")
				--EDITBOX:HighlightText()
			else
				ziprint("拍卖商品列表未打开")
			end
		else
			ziprint("拍卖界面未打开")
		end
	end
	PyArea:SetFocus()
end

function Toggle_SAVE_MEM()
	if SAVE_MEM  == 'off' then
		SAVE_MEM = 'on'
	else 
		SAVE_MEM = 'off'
	end
	Update_Check_SAVE_MEM()
	
end

function Update_Check_SAVE_MEM()
	if SAVE_MEM  == 'on' then
		Check_SAVE_MEM:SetChecked(true)
	else 
		Check_SAVE_MEM:SetChecked(nil)
	end
end
