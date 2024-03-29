﻿--主脚本

require "imgui"
require "Robot"

local clearColor = { 0, 0, 0 }
--local testImg = nil
local bShowDemoWindow = false

---------------------------------------------------------------------
-- 图形化Log窗口, 采用imgui实现
-- 使用方法，主线程调用:
--  theAppLog.AddLog("Hello world");
--  theAppLog.Draw("title");
local theAppLog = 
{
    Buf = "",
    ScrollToBottom = true,

    Clear = function(self)
		self.Buf = ""
	end,

    AddLog = function(self, content)
		self.Buf = self.Buf .. os.date("%H:%M:%S ", os.time()) .. content .. "\n"
		self.ScrollToBottom = true;
	end,

    Draw = function(self, title, open)
        imgui.SetNextWindowSize(700, 400, "imguiCond_FirstUseEver");
        imgui.Begin(title, p_open);
        if (imgui.Button("Clear")) then
			self:Clear();
		end
        
		imgui.SameLine();
        local copy = imgui.Button("Copy");
        imgui.Separator();
		
        imgui.BeginChild("scrolling", 0, 0, false, "imguiWindowFlags_HorizontalScrollbar");
        if copy then
			imgui.LogToClipboard();
		end

		imgui.TextUnformatted(self.Buf);

        if (self.ScrollToBottom) then
            imgui.SetScrollHere(1.0);
		end
			
        self.ScrollToBottom = false;
        imgui.EndChild();
        imgui.End();
    end
}

---------------------------------------------------------------------
--
-- LOVE callbacks
--
function love.load(arg)

	imgui.AddFontFromFileTTF("simhei.ttf", 16)
	theAppLog:AddLog("This a test log. 可以包含汉字。");
	
	for k, v in pairs(arg) do
		theAppLog:AddLog("Args: " .. k .. " " .. v);
	end
	
	--Wolves.SetConsoleTitle("Robot:" .. arg[1])
	love.window.setTitle("Robot:" .. arg[1])

	if not Wolves.Initialize(arg[1]) then
		print("Wolves.Initialize() failed!")
		return
	else
		Wolves.LogInfo("Wolves.Initialize() OK")

		Wolves.SharedManager.CreateThread("Thread_Game", "ScriptRobot/RobotLogic.lua")
	end

	--testImg = love.graphics.newImage("test.png")

end

function love.update(dt)
    imgui.NewFrame()
	
	-- 收到辅助线程消息
	local st = Wolves.SharedManager.FetchCurThreadMessage()
	if st ~= nil and st.type == "Log" then
		theAppLog:AddLog("[".. st.level .. "] " .. st.data)
	end

	local EGenericEvent =
	{
		eGE_None            = 0,
		eGE_UserPause		= 1,
		eGE_UserUnPause		= 2,
		eGE_UserStop		= 3,
		eGE_UserQuit		= 4,
		eGE_EmuReady		= 5,
		eGE_EmuStarting		= 6,
		eGE_AppRestarting	= 7,
		eGE_Abnormal		= 8,
		eGE_Count			= 9,
	}
	
	local ret = Wolves.Update(dt)
	if ret == EGenericEvent.eGE_UserPause then
		Wolves.SharedManager.PauseThread("Thread_Game")
	elseif ret == EGenericEvent.eGE_UserUnPause then
		Wolves.SharedManager.ResumeThread("Thread_Game")
	elseif ret == EGenericEvent.eGE_UserQuit then
		Wolves.SharedManager.AbortThread("Thread_Game")
	end

end

function love.draw()

	local bQuitApp = false
	local bMenuClicked = false
	
    -- Menu
    if imgui.BeginMainMenuBar() then
        if imgui.BeginMenu("File") then
			if imgui.MenuItem("Show Demo window") then
				bShowDemoWindow = not bShowDemoWindow
			end
            bQuitApp = imgui.MenuItem("退出")
            imgui.EndMenu()
        end
        imgui.EndMainMenuBar()
    end

    love.graphics.clear(clearColor[1], clearColor[2], clearColor[3])
	
	--love.graphics.draw(testImg, 0, 0)
	
	theAppLog:Draw("Log", true);
	
	if bShowDemoWindow then
		imgui.ShowDemoWindow(true)
	end

    imgui.Render();
	
	if bQuitApp then

		local t = Wolves.SharedManager.NewSharedTable()
		t.type = "Quit"
		-- 发消息给辅助线程
		Wolves.SharedManager.SendMessageToThread("Thread_Game", t)

		love.window.close()
		love.quit()
	end
end

function love.quit()
    imgui.ShutDown()

	Wolves.Finalize();
end

--
-- User inputs
--
function love.textinput(t)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.keypressed(key)
    imgui.KeyPressed(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.mousemoved(x, y)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousepressed(x, y, button)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousereleased(x, y, button)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

