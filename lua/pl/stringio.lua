--- reading and writing strings using Lua IO.
-- @class module
-- @name pl.stringio

local getmetatable,tostring,unpack,tonumber = getmetatable,tostring,unpack,tonumber
local concat,append = table.concat,table.insert

local stringio = {}

--- Writer class
local SW = {}
SW.__index = SW
 
function SW:write(...)
    local args = {...} --arguments may not be nil!
    for i = 1, #args do 
        append(self.tbl,tostring(args[i]))
    end
end
 
function SW:writef(fmt,...)
    self:write(fmt:format(...))
end
 
function SW:value()
    return concat(self.tbl)
end

--- Reader class
local SR = {}
SR.__index = SR
 
function SR:_read(fmt)
    local i,str = self.i,self.str
    local sz = #str
    if i >= sz then return nil end
    local res
    if fmt == nil or fmt == '*l' then
        local idx = str:find('\n',i) or (sz+1)
        res = str:sub(i,idx-1)
        self.i = idx+1
    elseif fmt == '*a' then
        res = str:sub(i)
        self.i = sz
    elseif fmt == '*n' then
        local _,i2,i2,idx
        _,idx = str:find ('%s*%d+',i)
        _,i2 = str:find ('%.%d+',idx+1)
        if i2 then idx = i2 end
        _,i2 = str:find ('[eE][%+%-]*%d+',idx+1)
        if i2 then idx = i2 end   
        local val = str:sub(i,idx)
        res = tonumber(val)
        self.i = idx+1
    elseif type(fmt) == 'number' then   
        res = str:sub(i,i+fmt-1)
        self.i = i + fmt
    else
        error("bad read format",2)
    end
    return res
end
 
function SR:read(...) 
    local fmts = {...} 
    if #fmts <= 1 then 
        return self:_read(fmts[1])
    else
        local res = {}
        for i = 1, #fmts do
            res[i] = self:_read(fmts[i])
        end
        return unpack(res)
    end
end
 
function SR:seek(whence,offset)
    local base
    whence = whence or 'cur'
    offset = offset or 0
    if whence == 'set' then
        base = 1
    elseif whence == 'cur' then
        base = self.i
    elseif whence == 'end' then
        base = #self.str
    end
    self.i = base + offset
    return self.i
end
 
function SR:lines()
    return function()
        return self:read()
    end
end
 
--- create a file-like object which can be used to construct a string.
-- The resulting object has an extra value() method for
-- retrieving the string value.
--  @usage f = create(); f:write('hello, dolly\n'); print(f:value()) 
function stringio.create()
    return setmetatable({tbl={}},SW)
end

--- create a file-like object for reading from a given string.
-- @param s The input string.
function stringio.open(s)
    return setmetatable({str=s,i=1},SR)
end

return stringio
