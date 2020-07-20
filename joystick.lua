-- 向量

local vec2 = nil

local vmt = {
    __sub = function (self, v)
        return vec2(self.x - v.x, self.y - v.y) 
    end,
    __add = function (self, v)
        return vec2(self.x + v.x, self.y + v.y) 
    end,
    __div = function (self, n)
        return vec2(self.x / n, self.y / n) 
    end,
    __mul = function (self, n)
        return vec2(self.x * n, self.y * n)
    end,
    __eq = function (self, v)
        return self.x == v.x and self.y == v.y
    end,
    __pow = function (self, v)
        return self.x * v.x + self.y * v.y
    end,
}

local function _norm(self, s)
    local rsl = self:clone()
    if s then rsl = rsl - s end
    local m = math.sqrt(self.x^2 + self.y^2)
    if m ~= 0 then
        rsl = rsl / m
    end
    return rsl
end

local function _clone(self)
    return vec2(self.x, self.y)
end

local function _norml(self)
    return vec2(-self.y, self.x)
end

local function _distance(self, v)
    return math.sqrt((self.x - v.x)^2 + (self.y - v.y)^2)
end

local function _length(self)
    return self:distance(vec2(0, 0))
end

local function _rotate(self, center, r)
    return vec2((self.x - center.x) * math.cos(r) - (self.y - center.y) * math.sin(r) + center.x,
            (self.x - center.x) * math.sin(r) + (self.y - center.y) * math.cos(r) + center.y)
end

vec2 = function (x, y)
    return setmetatable({x = x, y = y, unpack = function (self) return self.x, self.y end, rotate = _rotate, normL = _norml, normalize = _norm, clone = _clone, distance = _distance, length = _length}, vmt)
end

-- 类

local function deepCopy(tbl, rsl)
    for k, v in pairs(tbl) do
        local vt = type(v)
        if vt == "table" then
            rsl[k] = {}
            deepCopy(v, rsl[k])
        else
            rsl[k] = v
        end
    end
end

local mt = {
    __call = function (self, ...)
        local arg = {...}
        local rsl = { __class = true }
        deepCopy(self, rsl)
        if self.extend then
            rsl = self:extend(rsl, ...)
        else
            local argf = arg[1]
            local argft = type(argf)
            if argft == "function" then
                rsl.init = argf
            elseif argft == "table" then
                deepCopy(argf, rsl)
            end
        end
        return rsl
    end
}

local class = function (init)
    local rsl = { __class = true }
    local it = type(init)
    if it == "function" then
        rsl.init = init
        init(rsl)
    elseif it == "table" then
        deepCopy(init, rsl)
    end
    return setmetatable(rsl, mt)
end

-- 摇杆

local function clamp(min, x, max)
    return math.min(max, math.max(min, x))
end

local joystick = class {
    extend = function (self, rsl, x, y, r, br)
        rsl.x, rsl.y = x, y
        rsl.btnX, rsl.btnY = x, y
        rsl.radius = r
        rsl.btnRadius = br
        rsl.isTouched = false
        return rsl
    end,
    update = function (self, dt, getMousePos, getMouseReleased)
        local mx, my = getMousePos()
        local mousePos = vec2(mx, my)
        local dist = mousePos:distance(vec2(self.x, self.y))
        if self.isTouched then
            self.isTouched = not getMouseReleased()
            local rx, ry
            local sub = vec2(mx - self.x, my - self.y)
            local rad = self.radius
            if dist <= self.radius then
                rx, ry = mx, my
            else
                local normal = sub:normalize()
                rx = rad*normal.x + self.x
                ry = rad*normal.y + self.y
            end
            self.btnX, self.btnY = rx, ry
            return (sub/rad):unpack()
        else
            self.isTouched = dist <= self.radius
        end
        return 0, 0
    end,
    draw = function (self)
        -- 可以自定义
        -- 外圈
        --    ellipse(self.x, self.y, self.radius*2)
        -- 摇杆按钮
        --    ellipse(self.btnX, self.btnY, self.btnRadius*2)
    end,
    -- getMousePos 获取当前（k）触点位置
    -- getMouseReleased 获取当前（k）触点是否松开
}

-- 方便使用，做的摇杆组

local joystickGroup = class {
    children = {},
    extend = function (self, rsl, pos, release)
        rsl.getMousePos, rsl.getMouseReleased = pos, release
        return rsl
    end,
    add = function (self, k, v)
        local children = self.children
        local child = children[k]
        if child then
            self:remove(k)
        end
        children[k] = v
    end,
    getMousePos = function () end,
    getMouseReleased = function () end,
    remove = function (self, k)
        self.children[k] = nil
        collectgarbage"collect"
    end,
    update = function (self, dt)
        for _, child in pairs(self.children) do
            child:update(dt, self.getMousePos, self.getMouseReleased)
        end
    end,
    draw = function (self)
        for _, child in pairs(self.children) do
            child:draw()
        end
    end
}

return {
    joystick = joystick,
    joystickGroup = joystickGroup
}
