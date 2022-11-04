function all(comparator,elements,transformer)
  for index,element in ipairs(elements) do
    element = transformer and transformer(element) or element
    if element ~= comparator then
      return false,index
    end
  end
  return true
end
  
function none(comparator,elements,transformer)
  for index,element in ipairs(elements) do
    element = transformer and transformer(element) or element
    if element == comparator then
      return false,index
    end
  end
  return true
end
  
function is(comparator,elements,transformer)
  for index,element in ipairs(elements) do
    element = transformer and transformer(element) or element
    if element == comparator then
      return true,index
    end
  end
  return false
end

--------------------------------------------------------------------------------------------------------------------------

function readonly(t)
  t = t or {}
  local proxy = {}
  local mt = {
    __index = t,
    __type = "table:ro",
    __newindex = function (t,k,v)
                   error("attempt to update a read-only table", 2)
                 end
    }
  setmetatable(proxy, mt)
  return proxy
end

function class(name)
  local constructor = function (name,base,props)
    local baseClass = _ENV[base]
    
    local metamethods = {"__newindex","__mode","__call","__tostring","__unm","__concat",
                         "__len","__pairs","__ipairs","__gc","__name","__close","__le",
                         "__add","__sub","__mul","__div","__idiv","__mod","__pow","__lt",
                         "__band","__bor","__bxor","__bnot","__shl","__shr","__eq",
                         "__index","__immutable"}

    local new_class = props
    local new_class_mt = {}

    new_class.__metatable_ = new_class_mt

    for _,method in ipairs(metamethods) do
      new_class_mt[method] = new_class[method]
      new_class[method] = nil
    end

    if new_class_mt.__index == nil then
      new_class_mt.__index = new_class
    end

    new_class_mt.__type = name

    if nil ~= baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end

    function new_class:new(...)
      local newinst = setmetatable({}, self.__metatable_)
      rawset(newinst,"__metatable_",nil)
      if type(rawget(newinst,"constructor")) == "function" then
        rawget(newinst,"constructor")(...)
      end
      rawset(newinst,"constructor",nil)
      return newinst
    end

    _ENV[name] = new_class
  end

  return function (props)
           if type(props) == "table" then
             constructor(name,nil,props)
           else
             return function (_)
                      local base = props
                      props = _
                      constructor(name,base,props)
                    end
           end
         end
end

function new(class_name,props)
  return _ENV[class_name]:new(props)
end

function with(object)
  return function (properties)
           local meta = getmetatable(object) or {}
           for k, v in pairs(properties) do
             if type(object[k]) == "function" then
               if (type(object) == "string") or (meta.__immutable) then
                 object = object[k](object,table.unpack(v))
               else
                 object[k](object,table.unpack(v))
               end
             else
               object[k] = v
             end
           end
           return object 
         end
end

function try(fn,...)
  local status, err = pcall(fn,...)

  local metatable = {
    __index = {
      catch = function (self,f)
                if not self.status then
                  f(debug.traceback(self.err,2))
                end
                return self
              end;
      finally = function (self,f)
                  if type(f) == "function" then
                    f()
                  end
                end
    }
  }

  local result = {status = status, err = err}

  return setmetatable(result,metatable)
end

function literal(str)
  local special_chars = {"(", ")", ".", "%", "+", "-", "*", "?", "[", "]", "^", "$"}  
  local result = ""
  
  for char in str:gmatch(".") do
    result = result..(is(char,special_chars) and "%"..char or char)
  end
  
  return result
end

function switch(value)
  return function (cases)
           for case, output_value in pairs(cases) do
             if value == case then
               if type(output_value) == "function" then
                 return output_value ()
               else
                   return output_value
               end
             end
           end
           return type(cases.default) == "function" and cases.default() or cases.default
         end
end

function charset(classes)
  classes = classes:upper()
  
  local all_chars = ""
  local result = {}
  
  for i=0,255 do
    all_chars = all_chars..string.char(i)
  end
  
  for char in classes:gmatch(".") do
    local vchars = all_chars:gsub("%"..char,"")
    for vchar in vchars:gmatch(".") do
      result[#result+1] = vchar
    end
  end
  
  return table.unpack(result)
end

function wrap(function_original,wrapper_function)
  local proxy_mt = {
    __metatable = readonly {__type = "function",__metatable = {}};
    __newindex = function (self) error("attempt to index a function value",0) end;
    __call = wrapper_function
  }

  return setmetatable({original_function = function_original},proxy_mt)
end

type = wrap (type,
         function (self,any)
           local any_type = self.original_function(any)

           if any_type ~= "table" then
             return any_type
           elseif getmetatable(any) then
             return getmetatable(any).__type and tostring(getmetatable(any).__type) or "table"
           else
             return "table"
           end
         end
       )

function const(t)
  for k,v in pairs(t) do
    if rawget(_ENV,"_ENV_CONSTANTS")[k] then
      error("attempt to update a read-only variable", 2)
    end
    rawset(rawget(_ENV,"_ENV_CONSTANTS"),k,v)
  end
end

--------------------------------------------------------------------------------------------------------------------------

_ENV_CONSTANTS = readonly {}
_ENV_VARIABLES = readonly {}

_env_mt = {}

function _env_mt:__index(k)
  if rawget(self,"_ENV_CONSTANTS")[k] then
    return rawget(self,"_ENV_CONSTANTS")[k]
  end
  return rawget(self,"_ENV_VARIABLES")[k]
end

function _env_mt:__newindex(k,v)
  if rawget(self,"_ENV_CONSTANTS")[k] then
    error("attempt to update a read-only variable", 2)
  end
  rawset(rawget(self,"_ENV_VARIABLES"),k,v)
end

setmetatable(_ENV,_env_mt)

--------------------------------------------------------------------------------------------------------------------------

string.ascii_sub = string.sub

function string.len(str)
  return utf8.len(str)
end


function string.sub(str,s,e)
  local str_len = utf8.len(str)

  if s<0 and e == nil then
    s = str_len-math.abs(s)+1
    e = str_len
  elseif s<0 and e<0 then
    s = str_len-math.abs(s)+1
    e = str_len-math.abs(e)+1
  elseif tonumber(e) then
    e = e or str_len
  elseif e<0 then 
    e = str_len-math.abs(e)+1
  end

  local result = ""

  local i = 1
  for p, c in utf8.codes(str) do
    if i >= s then
      if i>e then break end
      result = result..utf8.char(c)
    end
    i = i+1
  end
  return result
end

function string.lower(str)
  local result = ""
  local upper = {[65]=97,  [66]=98,  [67]=99,  [68]=100, [69]=101, [70]=102, [71]=103, [72]=104,
                 [74]=106, [75]=107, [76]=108, [77]=109, [78]=110, [79]=111, [80]=112, [81]=113,
                 [83]=115, [84]=116, [85]=117, [86]=118, [87]=119, [88]=120, [89]=121, [90]=122,
                 [193]=225,[194]=226,[195]=227,[196]=228,[197]=229,[198]=230,[199]=231,[200]=232,
                 [201]=233,[202]=234,[203]=235,[204]=236,[205]=237,[206]=238,[207]=239,[208]=240,
                 [209]=241,[210]=242,[211]=243,[212]=244,[213]=245,[214]=246,[216]=248,[217]=249,
                 [218]=250,[219]=251,[220]=252,[221]=253,[222]=254,[376]=255,[73]=105, [82]=114,
                 [192]=224};

  for _,i in utf8.codes(str) do
    result = result..utf8.char(upper[i]==nil and i or upper[i])
  end
  return result
end

function string.upper(str)
  local result = ""
  lower = {[97]=65,[98]=66,[99]=67,[100]=68,[101]=69,[102]=70,[103]=71,[104]=72,[105]=73,
           [106]=74,[107]=75,[108]=76,[109]=77,[110]=78,[111]=79,[112]=80,[113]=81,[114]=82,
           [115]=83,[116]=84,[117]=85,[118]=86,[119]=87,[120]=88,[121]=89,[122]=90,[224]=192,
           [225]=193,[226]=194,[227]=195,[228]=196,[229]=197,[230]=198,[231]=199,[232]=200,
           [233]=201,[234]=202,[235]=203,[236]=204,[237]=205,[238]=206,[239]=207,[240]=208,
           [241]=209,[242]=210,[243]=211,[244]=212,[245]=213,[246]=214,[248]=216,[249]=217,
           [250]=218,[251]=219,[252]=220,[253]=221,[254]=222,[255]=376}

  for _,i in utf8.codes(str) do
    result = result..utf8.char(lower[i]==nil and i or lower[i])
  end
  return result
end

function string.reverse(str)
  local result = ""
  for _,i in utf8.codes(str) do
    result = utf8.char(i)..result
  end
  return result
end

function string.lines(str,preserve_empty)
  return str:gmatch("[^\r\n]"..(preserve_empty and "*" or "+"))
end

function string:chars()
    local i = 0
    return function ()
        i = i + 1
        return i <= self:len() and self:sub(i, i) or nil
    end
end

function string.ltrim(s)
  return s:gsub("^%s+", "")
end

function string.rtrim(s)
  return s:gsub("%s+$", "")
end

function string.htrim(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

function string.itrim(s)
  return s:gsub("%s+"," ")
end

function string.trim(s)
  return s:htrim():itrim()
end

function string.gfind(str,pattern,start)
  start = tonumber(start) or 1
  return function ()
           local s,e = str:find(pattern,start)
           if s then
              start = s+1
              return s,e
           end
         end
end

function string.split(text,sep,preserve_quotes)
  sep = sep or ";"
  local spat, epat, buf, quoted = [=[^(['"])]=], [=[(['"])$]=]
  local blocks = {}
  
  for str in text:gmatch("[^"..literal(sep).."]+") do
    local squoted = str:match(spat)
    local equoted = str:match(epat)
    local escaped = str:match([=[(\*)['"]$]=])
    if squoted and not quoted and not equoted then
      buf, quoted = str, squoted
    elseif buf and equoted == quoted and #escaped % 2 == 0 then
      str, buf, quoted = buf .. sep .. str, nil, nil
    elseif buf then
      buf = buf .. sep .. str
    end
    if not buf then
      blocks[#blocks+1] = (str:gsub(spat,""):gsub(epat,""))
    end
  end
  if buf then
    error("Missing matching quote for "..buf)
  end
  
  return ipairs(blocks)
end

function io.read(...)
  local t = {...}
  if t[1] == "*f" then
    local file = io.open(t[2], "rb")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
  end
  return io.input():read(...)
end

--------------------------------------------------------------------------------------------------------------------------

const {
  __LOVELY_VERSION__={1;0;7}
}
