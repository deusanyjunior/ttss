--------------------------------------
-- Twinkle, Twinkle Smartphone Star --
-- Team: Antonio D. de Carvalho J.  --
--       Zachary Boulanger          --
--------------------------------------


FreeAllRegions()
FreeAllFlowboxes()
DPrint("")


-- Project in Landscape
SetExternalOrientation(2)




-------------------------------------------------------------------------------------
--              Shared              -------------------------------------------------
--             Resources            -------------------------------------------------
-------------------------------------------------------------------------------------




-- variables
b1 = Region()
b2 = Region()
keysC = {}
keysP = {}
keyMarker = {}
numberOfKeys = 8
keyHeight = ScreenHeight()/numberOfKeys
keyWidth = ScreenWidth()
notes = {}
backupNotes = {}
numberOfNotes = 0
noteHeight = keyHeight/1.5
noteWidth = keyHeight/1.5
topOffset = noteHeight + (keyHeight - noteHeight)/2


friends = {}
friendsKey = {}


-- sound stuff
samples = FlowBox(FBSample)
push = FlowBox(FBPush)
pushLoop = FlowBox(FBPush)
pushPos = FlowBox(FBPush)
dac = FlowBox(FBDac)


samples:AddFile(DocumentPath("myC4.wav"))
samples:AddFile(DocumentPath("myD4.wav"))
samples:AddFile(DocumentPath("myE4.wav"))
samples:AddFile(DocumentPath("myF4.wav"))
samples:AddFile(DocumentPath("myG4.wav"))
samples:AddFile(DocumentPath("myA4.wav"))
samples:AddFile(DocumentPath("myB4.wav"))
samples:AddFile(DocumentPath("myC5.wav"))


pushLoop.Out:SetPush(samples.Loop)
pushLoop:Push(0)


pushPos.Out:SetPush(samples.Pos)
pushPos:Push(1)


push.Out:SetPush(samples.Sample)
dac.In:SetPull(samples.Out)


-- colors keys
c = { {55,55,55,255}, -- black
        {255,0,0,255}, -- red
        {255,200,0,255}, -- orange
        {255,255,0,255}, -- yellow
        {0,255,0,255}, -- green
        {0,255,255,255}, -- indigo
        {75,0,130,255}, -- violet
        {55,55,55,255}, -- black
        {255,255,255,255}, -- white
        {0,0,255,255} -- blue
}


-- colors pressed keys
cp = { {155,155,155,255}, -- black
        {255,155,155,255}, -- red
        {255,200,155,255}, -- orange
        {255,255,155,255}, -- yellow
        {155,255,155,255}, -- green
        {205,255,255,255}, -- indigo
        {155,0,190,255}, -- violet
        {155,155,155,255}, -- black
        {205,205,205,255}, -- white
        {155,155,255,255} -- blue
}


x = ScreenWidth()
-- move note down screen
function moveNote(self, elapsed)
        self.position = self.position-elapsed*50
        x = self:Left()/ScreenWidth()*170+50 + self.colordev
        
--        x = math.random(50,220)
        self.t:SetSolidColor(x,x,x,255)
        self:SetAnchor("RIGHT",self:Parent(),"RIGHT",self.position,0)
        if self.position < ScreenWidth()*-1 then
                self:Handle("OnUpdate",nil)
        end
end


local toggle = 0


-- create note that's falling down screen
function createNote(self)
        --DPrint("create "..self.number)
        --DPrint("")
        local newNote = nil
        
        newNote = Region()
        newNote.t = newNote:Texture(DocumentPath("ball128.png")) -- Slow operation: Preload a few


        newNote.number = self.number
        newNote.t:SetBlendMode("ALPHAKEY")
        newNote:SetHeight(noteHeight)
        newNote:SetWidth(noteWidth)
        newNote.position = noteWidth
        newNote:SetAnchor("RIGHT",self,"RIGHT",newNote.position,0)
        newNote.colordev = toggle * 35
        newNote:MoveToTop()
        toggle = 1 - toggle
        
        newNote:Handle("OnUpdate",moveNote)
        if composerMode == false then
                newNote:EnableInput(true)
                newNote:Handle("OnTouchDown", pressedBottom)
        end
        newNote:Show()
        table.insert(notes,newNote)
end


function addPoints(playerId)


        local pKey = friendsKey[playerId]
        local pPoints = keysC[pKey].points+1
        keysC[pKey].player = playerId
        keysC[pKey].points = pPoints
        keysC[pKey].tl = keysC[pKey]:TextLabel()
        keysC[pKey].tl:SetLabel(playerId.."\n"..pPoints)
        keysC[pKey].tl:SetRotation(-90)
        keysC[pKey].tl:SetFontHeight(25)
end


-------------------------------------------------------------------------------------
--              Page 2              -------------------------------------------------
--           Composer Page          -------------------------------------------------
-------------------------------------------------------------------------------------


SetPage(2)


-- bg region for OSC
bgC = Region()
bgC.t = bgC:Texture()
bgC.t:SetTexture(255,255,255,255)
bgC:SetWidth(ScreenWidth())
bgC:SetHeight(ScreenHeight())
bgC:Show()


composerMode = true


function pressed(self)
        local nP = self.number
        self.t:SetTexture(cp[nP][1],cp[nP][2],cp[nP][3],cp[nP][4])
        pushPos:Push(0)
        push:Push(self.number/8-1/16)
        pushLoop:Push(0)
        if composerMode == true then
                sendNote(nP)
        end
        createNote(self)
end


function released(self)
  local nR = self.number
        self.t:SetTexture(c[nR][1],c[nR][2],c[nR][3],c[nR][4])
end


for i = 1, numberOfKeys do
        local newKey = Region()
        newKey.number = i
        newKey:SetHeight(keyHeight)
        newKey:SetWidth(keyWidth)
        newKey.t = newKey:Texture(c[i][1],c[i][2],c[i][3],c[i][4])
        newKey:SetAnchor("BOTTOMLEFT",0,ScreenHeight()-keyHeight*(i))
        newKey:Handle("OnTouchDown", pressed)
        --newKey:Handle("OnEnter", pressed)
        newKey:Handle("OnTouchUp", released)
  newKey:Handle("OnLeave", released)
        newKey:EnableInput(true)
        newKey.player = ""
        newKey.points = 0
        newKey:Show()
        createNote(newKey) -- preload
        keysC[i] = newKey
end




--------------------------------------------------------------------------------------
--              Page 3              --------------------------------------------------
--            Player Page           --------------------------------------------------
--------------------------------------------------------------------------------------




SetPage(3)


composerMode = false


-- bg region for OSC
bgP = Region()
bgP.t = bgC:Texture()
bgP.t:SetTexture(255,255,255,255)
bgP:SetWidth(ScreenWidth())
bgP:SetHeight(ScreenHeight())
bgP:Show()


-- triggers when note is pressed and acts when it is in bottom screen
function pressedBottom(self)
        if self.position < (ScreenWidth()-keyHeight)*-1 then
                local loc = 8 - (self:Top() - topOffset)/keyHeight
                keysP[loc].num = keysP[loc].num + 1
                keysP[loc].tl:SetLabel(keysP[loc].num)


                pushPos:Push(0)
                push:Push(self.number/8-1/16)
                pushLoop:Push(0)
                sendNote(self.number)
        end
end


for i = 1, numberOfKeys do
        local newKey = Region()
        newKey.number = i
        newKey:SetHeight(keyHeight)
        newKey:SetWidth(keyWidth)
        newKey.t = newKey:Texture(c[i][1],c[i][2],c[i][3],c[i][4])
        newKey:SetAnchor("BOTTOMLEFT",0,ScreenHeight()-keyHeight*(i))
        newKey:Show()


        newKey.num = 0
        newKey.tl = newKey:TextLabel()
        newKey.tl:SetLabel(newKey.num)
        newKey.tl:SetRotation(-90)
        newKey.tl:SetFontHeight(25)


        -- newKey:Handle("OnTouchDown", nil)
        -- newKey:Handle("OnEnter", nil)
        -- newKey:Handle("OnTouchUp", nil)
        -- newKey:Handle("OnLeave", nil)
        newKey:EnableInput(true)


        keysP[i] = newKey


        local newKeyMarker = Region()
        newKeyMarker.number = i
        newKeyMarker:SetHeight(keyHeight)
        newKeyMarker:SetWidth(keyHeight)
        newKeyMarker.t = newKeyMarker:Texture()
        newKeyMarker.t:SetTexture(255,255,255,175)
        newKeyMarker:SetAnchor("BOTTOMLEFT",0,ScreenHeight()-keyHeight*(i))
        newKeyMarker.t:SetBlendMode("BLEND")
        newKeyMarker:Show()
        keyMarker[i] = newKeyMarker
end


-------------------------------------------------------------------------------------
--              Page 1              -------------------------------------------------
--            Switch Page           -------------------------------------------------
-------------------------------------------------------------------------------------


SetPage(1)


currentPage = 1


bg = Region()
bg.t = bg:Texture()
bg:Show()
bg.t:SetTexture(255,0,0,255)
bg:SetWidth(ScreenWidth())
bg:SetHeight(ScreenHeight())


function toPage2(self)
        b1:Hide()
        b2:Hide()
        b1:EnableInput(false)
        b2:EnableInput(false)


        composerMode = true


        currentPage = 2
        SetPage(currentPage)
end


function toPage3(self)
        b1:Hide()
        b2:Hide()
        b1:EnableInput(false)
        b2:EnableInput(false)


        composerMode = false


        currentPage = 3
        SetPage(currentPage)
end


-- "button" to get to Composer Section
b1.t = b1:Texture()
b1.t:SetTexture(0,255,0,255)
b1:SetWidth(ScreenWidth())
b1:SetHeight(ScreenHeight()/2)
b1:SetAnchor("BOTTOMLEFT",0,ScreenHeight()-ScreenHeight()/2)
b1.tl = b1:TextLabel()
b1.tl:SetLabel("Go to Composer Page")
b1.tl:SetRotation(90)
b1.tl:SetFontHeight(15)
b1.tl:SetColor(0,0,0,255)
b1:EnableInput(true)
b1:Handle("OnTouchDown", toPage2)
b1:Show()


-- "button" to get to Player Section
b2.t = b2:Texture()
b2.t:SetTexture(0,255,255,255)
b2:SetWidth(ScreenWidth())
b2:SetHeight(ScreenHeight()/2)
b2:SetAnchor("BOTTOMLEFT",0,0)
b2.tl = b2:TextLabel()
b2.tl:SetLabel("Go to Player Page")
b2.tl:SetRotation(90)
b2.tl:SetFontHeight(15)
b2.tl:SetColor(0,0,0,255)
b2:EnableInput(true)
b2:Handle("OnTouchDown", toPage3)
b2:Show()


b1:MoveToTop()
b2:MoveToTop()




-------------------------------------------------------------------------------------
--             Networking           -------------------------------------------------
--       Between sections/phones    -------------------------------------------------
-------------------------------------------------------------------------------------




local myIP, myPort = HTTPServer()


endPoint = string.find(myIP, '.', string.find(myIP, '.',string.find(myIP, '.',1, true)+1, true)+1, true)
local ownId = tonumber(string.sub(myIP, endPoint+1))


local function NewConnection(self, name)
        DPrint("new friend "..name)
        DPrint("")
        for j,u in pairs(friends) do
                if u == name then
                        return
                end
        end
        friendEndPoint = string.find(name, '.', string.find(name, '.',string.find(name, '.',1, true)+1, true)+1, true)
        friendId = tonumber(string.sub(name, friendEndPoint+1))
        table.insert(friends, name)
        friendsKey[friendId] = table.getn(friends)
end


local function LostConnection(self, name)
        for l,w in pairs(friends) do
                if w == name then
                        table.remove(friends,l)
                end
        end
end


function sendNote(noteToSend)
        DPrint("sent "..noteToSend)
        DPrint("")
        for indexIp = 1, table.getn(friends) do
                local ip = friends[indexIp]
                SendOSCMessage(ip,8888,"/urMus/numbers",noteToSend, ownId, currentPage)
        end
end


function gotOSC(self, noteReceived, senderId, senderPage)
        DPrint("got osc")
        DPrint("")
        if senderPage == 3 then
                addPoints(senderId)
        elseif senderPage == 2 then
                createNote(keysP[noteReceived])
        end
end


bg:Handle("OnNetConnect", NewConnection)
bgC:Handle("OnNetConnect", NewConnection)
bgP:Handle("OnNetConnect", NewConnection)


bg:Handle("OnNetDisconnect", LostConnection)
bgC:Handle("OnNetDisconnect", LostConnection)
bgP:Handle("OnNetDisconnect", LostConnection)


StartNetAdvertise("ttss",8889)
StartNetDiscovery("ttss")


bg:Handle("OnOSCMessage",gotOSC)
bgP:Handle("OnOSCMessage",gotOSC)
bgC:Handle("OnOSCMessage",gotOSC)


SetOSCPort(8888)
host, port = StartOSCListener()
