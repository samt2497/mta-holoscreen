RTE_Demo = nil
RTE_Holo = nil

addEventHandler( "onClientResourceStart", resourceRoot,
    function ( startedRes )
        local holoscreen,RT_ID,RTE = createHoloScreen(149,2482,16.5,40,0,90,1.35,2) --Create our holoscreen
		setElementData(holoscreen,"interactive","aim") -- Make it interactive on user aim
		if RTE then -- If we got the render Target of the screen then
			RTE_Demo = RTE
			RTE_Holo = holoscreen
			addEventHandler ( "onHoloScrenRender", RTE_Holo,drawHoloDemo) -- Event handler for every render of the holo screen
		end
    end
);

function drawHoloDemo()
	local width, height = dxGetMaterialSize(RTE_Demo)
	dxSetRenderTarget(RTE_Demo,true)
	--
		dxDrawRectangle (0,0,10,1000,tocolor(0,255,0,200),false)
		dxDrawRectangle (0,0,1000,1000,tocolor(0,255,255,200),false)
		local ix = getElementData(RTE_Holo,"ix")
		local iy = getElementData(RTE_Holo,"iy")
		if ix and iy then
			local tx = ix*width
			local ty = iy*height
			dxDrawLine (tx-13,ty, tx+13,ty,tocolor(255,0,0,255),1)
			dxDrawLine (tx,ty-13,tx,ty+13,tocolor(255,0,0,255),1)
		end
	--
	dxSetRenderTarget()
end
