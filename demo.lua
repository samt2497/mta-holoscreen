local holo
local RTE_w = 0
local RTE_h = 0

addEventHandler( "onClientResourceStart", resourceRoot,
    function ( startedRes )
       holo,RTE_w,RTE_h = createHoloScreen(149,2482,16.5,40,0,90,1.35,2) --Create our holoscreen
		setElementData(holo,"interactive","aim") 
		addEventHandler ( "onHoloScrenRender", holo,drawHoloDemo)
    end
);

function drawHoloDemo(rendertarget)
	dxSetRenderTarget(rendertarget,true)
	--
		dxDrawRectangle (0,0,10,RTE_h,tocolor(0,255,0,200),false)
		dxDrawRectangle (0,0,RTE_w,RTE_h,tocolor(0,255,255,200),false)
		local ix = (getElementData(holo,"ix") or -1)*RTE_w
		local iy = (getElementData(holo,"iy") or -1)*RTE_h
		if ix > 0 and iy > 0 then
			local tx = ix
			local ty = iy
			dxDrawLine (tx-8,ty, tx+8,ty,tocolor(255,255,255,255),3)
			dxDrawLine (tx,ty-8,tx,ty+8,tocolor(255,255,255,255),3)
		end
	--
	dxSetRenderTarget()
end
