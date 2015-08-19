prefix_RTID = "hsrt_"
PixPerUnit = 100
RenderDistance = 30
ActionDistance = 10
RTCache = {}
ix = 0


addEvent ( "onHoloScrenRender", true )

function getHRTE(holoscreen)
	if RTCache[holoscreen] then
		RTCache[holoscreen].stamp = getTickCount()
	else
		RTCache[holoscreen] = {}
		RTCache[holoscreen].RTE = dxCreateRenderTarget(getElementData(holoscreen,"rtw"),getElementData(holoscreen,"rth"),true)
		RTCache[holoscreen].stamp = getTickCount()
	end
	return RTCache[holoscreen].RTE
end

function createHoloScreen(x,y,z,rx,ry,rz,height,width)
	local created = nil
	local rtw,rth
	rtw = width*PixPerUnit
	rth = height*PixPerUnit
	local holoscreen = createElement("holoscreen")
	if holoscreen then
		setElementData(holoscreen,"height",height,false)
		setElementData(holoscreen,"width",width,false)
		setElementData(holoscreen,"rtw",rtw,false)
		setElementData(holoscreen,"rth",rth,false)
		setElementPosition(holoscreen,x,y,z)
		setElementData(holoscreen,"rx",rx,false)
		setElementData(holoscreen,"ry",ry,false)
		setElementData(holoscreen,"rz",rz,false)
		return holoscreen,rtw,rth
	else
		return false
	end
end


addEventHandler("onClientElementDataChange", getRootElement(),
function(dataName)
	if getElementType(source) == "holoscreen" then
		if dataName == "RTID" then 
		end
	end
end)

function getPositionFromMatrixOffset(m,offX,offY,offZ)
	local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
	local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
	local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
	return x, y, z
end

function getOffsetFromXYZ( mat, vec )
    mat[1][4] = 0
    mat[2][4] = 0
    mat[3][4] = 0
    mat[4][4] = 1
    mat = matrix.invert( mat )
    local offX = vec[1] * mat[1][1] + vec[2] * mat[2][1] + vec[3] * mat[3][1] + mat[4][1]
    local offY = vec[1] * mat[1][2] + vec[2] * mat[2][2] + vec[3] * mat[3][2] + mat[4][2]
    local offZ = vec[1] * mat[1][3] + vec[2] * mat[2][3] + vec[3] * mat[3][3] + mat[4][3]
    return offX, offY, offZ
end

function math.lerp(from,to,progress)
    return from + (to-from) * progress
end
function math.unlerp(from,to,lerp)
	return (lerp-from)/(to-from)	
end

function getEElementMatrix(element)
	local rx, ry, rz = getElementData(element,"rx"), getElementData(element,"ry"), getElementData(element,"rz")
	if rx == 0 then
		rx = 0.00001
	end
	if ry == 0 then
		ry = 0.00001
	end
		if rz == 0 then
		rz = 0.00001
	end
	rx, ry, rz = math.rad(rx), math.rad(ry), math.rad(rz)
	local matrix = {}
    matrix[1] = {}
    matrix[1][1] = math.cos(rz)*math.cos(ry) - math.sin(rz)*math.sin(rx)*math.sin(ry)
    matrix[1][2] = math.cos(ry)*math.sin(rz) + math.cos(rz)*math.sin(rx)*math.sin(ry)
    matrix[1][3] = -math.cos(rx)*math.sin(ry)
    matrix[1][4] = 1
 
    matrix[2] = {}
    matrix[2][1] = -math.cos(rx)*math.sin(rz)
    matrix[2][2] = math.cos(rz)*math.cos(rx)
    matrix[2][3] = math.sin(rx)
    matrix[2][4] = 1
 
    matrix[3] = {}
    matrix[3][1] = math.cos(rz)*math.sin(ry) + math.cos(ry)*math.sin(rz)*math.sin(rx)
    matrix[3][2] = math.sin(rz)*math.sin(ry) - math.cos(rz)*math.cos(ry)*math.sin(rx)
    matrix[3][3] = math.cos(rx)*math.cos(ry)
    matrix[3][4] = 1
 
    matrix[4] = {}
    matrix[4][1], matrix[4][2], matrix[4][3] = getElementPosition(element)
    matrix[4][4] = 1
 
	return matrix
end

function GarbageCollector()
	for holo,vals in pairs(RTCache) do
		if getTickCount()-vals.stamp > 5000 then
			destroyElement(vals.RTE)
			RTCache[holo] = nil
		end
	end
end
setTimer(GarbageCollector,3000,0)

function renderHoloScreens()
	local cx, cy, cz, clx, cly, clz = getCameraMatrix()
	for key,holoscreen in ipairs(getElementsByType ("holoscreen",root,true)) do 
		local matrix = getEElementMatrix(holoscreen)
		--local hx,hy,hz = getElementPosition(holoscreen)
		local hx,hy,hz = matrix[4][1], matrix[4][2], matrix[4][3]
		local hs_distance = getDistanceBetweenPoints3D(cx, cy, cz,hx,hy,hz)
		if hs_distance < RenderDistance then
			local hs_width = getElementData(holoscreen,"width")
			local hs_height =getElementData(holoscreen,"height")
			local ix,iy,iz = getPositionFromMatrixOffset(matrix,0,0,hs_height*.5)
			local ex,ey,ez = getPositionFromMatrixOffset(matrix,0,0,-hs_height*.5)
			local fx,fy,fz = getPositionFromMatrixOffset(matrix,0,hs_width,0)
			RTE = getHRTE(holoscreen)
			-- Test Interactive
			if hs_distance < ActionDistance then
				local interactive = getElementData(holoscreen,"interactive")
				if interactive then
					if interactive == "aim" then
						cstate = isPedDoingTask(localPlayer,"TASK_SIMPLE_USE_GUN")
						if cstate then				
							local tx,ty,tz = getPedTargetCollision(localPlayer)
							if not tx then
								tx,ty,tz =  getPedTargetEnd(localPlayer)
							end
							local ofx,ofy,ofz = getOffsetFromXYZ(matrix,{cx, cy, cz})
							local efx,efy,efz = getOffsetFromXYZ(matrix,{tx, ty, tz})
							local progress = math.unlerp(ofy,efy,0)
							local ix,iy,iz = interpolateBetween (ofx,ofy,ofz,efx,efy,efz,progress,"Linear")	
							if (ix > -hs_width*.5 and ix < hs_width*.5) and (iy > -hs_height*.5 and iy < hs_height*.5) then
								setElementData(holoscreen,"ix",(-ix+(hs_width*.5))/hs_width)
								setElementData(holoscreen,"iy",(-iz+(hs_height*.5))/hs_height)
							end
						end
					end
				end
			end
			--Send Signal
			triggerEvent ("onHoloScrenRender",holoscreen,RTE)
			--Draw IT			
			dxDrawMaterialLine3D (ix,iy,iz,ex,ey,ez,RTE,hs_width,white,fx,fy,fz)
		end
	end
end
addEventHandler ( "onClientRender", root,renderHoloScreens)