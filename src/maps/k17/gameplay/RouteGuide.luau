--!strict
-- Local navigation aid only. Server objective progression never uses this.
local Guide={}
function Guide.next(points: {{number}},position: {number},radius: number): ({number},string)
    assert(#points>0,"Empty route")
    local best,index=math.huge,1
    for i=2,#points do
        local a,b=points[i-1],points[i]
        local dx,dy,dz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
        local length=dx*dx+dy*dy+dz*dz
        local t=if length>0 then math.clamp(((position[1]-a[1])*dx+(position[2]-a[2])*dy+(position[3]-a[3])*dz)/length,0,1) else 0
        local distance=(position[1]-a[1]-dx*t)^2+(position[2]-a[2]-dy*t)^2+(position[3]-a[3]-dz*t)^2
        if distance<=best then best=distance;index=i end
    end
    local p=points[index]
    while index<#points and (position[1]-p[1])^2+(position[2]-p[2])^2+(position[3]-p[3])^2<=radius*radius do
        index+=1;p=points[index]
    end
    local hint=if p[2]<position[2]-5 then "Desça a escadaria" elseif p[2]>position[2]+5 then "Suba a escadaria" else "Próximo acesso"
    return p,hint
end
return table.freeze(Guide)
