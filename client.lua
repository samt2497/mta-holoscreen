prefix_RTID = "hsrt_"
PixPerUnit = 200
RenderDistance = 20
RTCache = {}
ix = 0


addEvent ( "onHoloScrenRender", true )

function createHoloScreen(x,y,z,rx,ry,rz,height,width,may_rt,may_hg)
	local RT_ID = nil
	local created = nil
	if type(may_rt) == "string" then
		local maye = getElementByID(may_rt)
		if isElement(maye) then
			RT_ID = maye
		end
	end
	if not RT_ID then
		if isElement(may_rt) then
			RT_ID = getElementID(may_rt)
		else
			local rtw = tonumber(may_rt) or 0
			local rth = tonumber(may_hg) or 0
			if rtw < 1 then
				rtw = width*PixPerUnit
			end
			if rth < 1 then
				rth = width*PixPerUnit
			end
			local crt = dxCreateRenderTarget(rtw,rth,true)
			ix = ix + 1
			RT_ID = prefix_RTID..ix
			setElementID(crt,RT_ID)
		end
	end
	local RTE = getElementByID(RT_ID)
	if isElement(RTE) then
		local holoscreen = createElement("holoscreen")
		setElementData(holoscreen,"RTID",RT_ID,false)
		setElementData(holoscreen,"height",height,false)
		setElementData(holoscreen,"width",width,false)
		setElementPosition(holoscreen,x,y,z)
		setElementData(holoscreen,"rx",rx,false)
		setElementData(holoscreen,"ry",ry,false)
		setElementData(holoscreen,"rz",rz,false)
		return holoscreen,RT_ID,RTE
	else
		return false
	end
end


addEventHandler("onClientElementDataChange", getRootElement(),
function(dataName)
	if getElementType(source) == "holoscreen" then
		if dataName == "RTID" then
			RTCache[source] = getElementData(source,dataName)
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
    mat = matrix.invert(mat)
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
			RTE = getElementByID(getElementData(holoscreen,"RTID"))
			-- Test Interactive
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
			--Send Signal
			triggerEvent ("onHoloScrenRender",holoscreen)
			--Draw IT			
			dxDrawMaterialLine3D (ix,iy,iz,ex,ey,ez,RTE,hs_width,white,fx,fy,fz)
		end
	end
end
addEventHandler ( "onClientRender", root,renderHoloScreens)