--[[ make.lua -- maker for the dialectica template

Copyright 2023 Julien Dutant
License MIT

]] 

-- Version of the Dialoa template
VERSION = '1.1'



-- 3 means that the workhouse root may be 3 folders up
--- for an article's workdir
DIALOA_DEPTH = 3

-- # Helper functions

SYSTEM = { darwin = 'mac', mingw32 = 'win', linux = 'nix' }
path = pandoc.path
type = pandoc.utils.type
stringify = pandoc.utils.stringify

--- # Lua
local function splitStrBy(str, sep)
    sep = sep or '%s'
    local t = {}
    for s in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(t, s)
    end
    return t
end

local function numsFromTo(a,b,step)
    a, b = tonumber(a), tonumber(b)
    step = tonumber(step)
    if not a or not b 
        or a < b and step and step <= 0
        or a > b and step and step >= 0 then
        return {}
    end
    step = step or a <= b and 1 or -1
    t = {}
    for i = a, b, step do
        table.insert(t,i)
    end
    return t
end

--- ## Logging

local function message(str)
    print('[LUA MAKER]', str)
end

--- ## File management

local function fileExists(filepath)
    local f = io.open( filepath , "r" )
    return f ~= nil and f:close() 
        or false
end

local function readFile(filepath)
    local f = io.open(filepath , "r" )
    if f ~= nil then
        result = f:read("a")
        f:close()
        return result
    end
end

---writeToFile: write string to file.
---@param contents string file contents
---@param filepath string file path
---@return nil | string status error message
local function writeToFile(contents, filepath)
  local f = io.open(filepath, 'w')
  if f ~= nil then 
    assert(f:write(contents), 'Cannot write file '..filepath)
	f:close()
  else
    return 'File not written'
  end
end

--- strip dir and extension
local function getBaseFilename(fpath)
    local base, _ = path.split_extension(
        path.filename(fpath)
    )
    return base
end

--- turn into a Linux-style path (safer to put in metadata files)
--- `...\...\` in Windows paths become escape chars when placed in yaml files
local function makeNixPath(fpath)
    local tbl = path.split(fpath)
    return table.concat(tbl, '/')
end
local function findDialoa(version, depth, file)
    local file = file or 'dialoa.yaml'
    local version = version or VERSION
    local depth = depth or DIALOA_DEPTH
    local dialoaDir = path.join { 'template', version }
    for i = 0, DIALOA_DEPTH do
        if fileExists(path.join{dialoaDir, file}) then
            return dialoaDir
        else
            dialoaDir = path.join { '..', dialoaDir}
        end
    end
end

-- # Options object

---@alias mode 'offprint'|'issue'|'book'|'bare'

local MODES = pandoc.List:new {'refs','offprint', 'issue', 'book', 'bare'}

---Lua's command line args are in a list of strings
---global variable `arg`
---@alias CLargs string[]

local FLAGS = {
    proof = 'proof',
    quiet = 'quiet',
    verbose = 'verbose',
}
local SINGLE_SHORTFLAGS = {
    p = 'proof',
}
-- combinable shortflags
local COMBINABLE_SHORTFLAGS = {
    p = 'proof',
    q = 'quiet',
    v = 'verbose',
}
--- keyvals
local KEYVALS = {
    master = 'master',
    pandoc = 'pandoc',
    chapter = 'chapter',
    mode = 'mode',
    format = 'format',
}
--- List single shortflags among shortflags
local SHORTFLAGS = {}
for _,tbl in ipairs( { SINGLE_SHORTFLAGS, COMBINABLE_SHORTFLAGS }) do
    for k,v in pairs(tbl) do
        SHORTFLAGS[k] = v
    end
end

---@class Options
---@field new fun(args: CLargs):Options create Options object
---@field pandoc string pandoc command
---@field template string path to the dialoa template dir
---@field master string filepath to the master file
---@field formats string[]
---@field modes mode[]
---@field chapters number[] note {0} for all files
---@field proof boolean
---@field verbosity 'quiet'|'verbose'|nil
---@field chapterFiles string[]
local Options = {}

---create an Options object
---@param args string[]
---@return object Options
function Options:new(args)
  o = {}
  setmetatable(o,self)
  self.__index = self

  while #args > 0 do
    args = self:readCLargs(args)
  end

  o:setup()

  return o
end

function Options:setup()

  -- provide default values
  if not self.template then
    self.template = findDialoa()
    assert(self.template, 'Could not find Dialoa template '
        .. tostring(VERSION))
  end

  self.system = SYSTEM[pandoc.system.os]
  assert(self.system, 'Cannot recognize system '..pandoc.system.os)

  if not self.pandoc then
    self.pandoc = 'pandoc'
  end

  if not self.master then
    self.master = 'master.md'
    assert(fileExists(self.master), 'Cannot find master file: '
    .. self.master)
  end

  if not self.modes then
    self.modes = { 'offprint' }
  end

  if not self.chapters then
    self.chapters = { 1 }
  end

  if not self.formats then
    if mode == 'offprint' then
        self.formats = { 'html' }
    else
        self.formats = { 'pdf' }
    end
  end

  if not self.proof then
    self.proof = false
  end

  self.templatePath = function (file, dir)
    dir = dir or ''
    return path.join {self.template, dir, file}
  end
end

--# Command Line Arguments processing

---checkArg: check that a string is a valid argument name
---@param str string argument to be checked
---@param map table|nil map of {arg = alias}
---@param msg string|nil error message if not found
---@return unknown
function Options:checkArg(str, map, msg)
    if map and map[str] then 
        return map[str]
    elseif msg then
        message(msg .. ': ' .. str)
    end
end

---read one flag
---@param flag string flag
---@param args string[] subsequent arguments
---@return string[] args subsequent arguments
function Options:readFlag(flag, args)

    if flag == 'proof' then
        self.proof = true
    elseif flage == 'quiet' then
        self.verbosity = 'quiet'
    elseif flag == 'verbose' then
        self.verbosity = 'verbose'
    else
        print('Not processing flag '..flag)
    end
    return args
end

--- read key = val
---@param key string
---@param val string
function Options:readKeyVal(key, val)

    if key == 'pandoc' then 
        self.pandoc = val
    elseif key == 'master' then
        self.master = val
    elseif key == 'chapter' then
        self.chapters = pandoc.List:new(splitStrBy(val,',')):map(
            function(chap) return tonumber(chap) end
        )
    elseif key == 'mode' then
        local modes = pandoc.List:new(splitStrBy(val,',')):map(
            function(mode)
                mode = 'vol' and 'issue' or mode
                return MODES:find(mode)
            end
        )
        self.modes = #modes > 0 and modes or nil
    elseif key == 'format' then
        local formats = pandoc.List:new(splitStrBy(val,',')):map(
            function(fmt) return (fmt == 'html'
                or fmt == 'pdf' 
                or fmt == 'latex'
                or fmt == 'epub'
                or fmt == 'jats') and fmt
                or fmt == 'tex' and 'latex'
                or nil
            end
        )
        self.formats = #formats > 0 and formats or nil
    else 
        print('Ignoring key '..key..' with value '..val)
    end
end

---read one pain argument
---@param arg string argument
---@param args string[] subsequent arguments
---@return string[] args subsequent arguments
function Options:readPlainArg(arg, args)
    local mode, format, chapter
    local patterns = {
        '^(refs)$',
        '^(all)(.*)',
        '^(vol)(.*)',
        '^(iss)(.*)',
        '^(book)(.*)',
        '^(bare)(.*)',
        '^(off)(%d+)(.*)',
        '^(offprint)(.*)',
        '^(off)(.*)',
        '^(offprints)(.*)',
    }

    for _,pattern in ipairs(patterns) do
        local head, suf, suff = arg:match(pattern)
        if head then
            -- 'offprint' and 'offprints' aliases of 'off'
            if head == 'offprint' or head == 'offprints' then
                head = 'off'
            end
            -- extract number argument when present
            if head == 'off' and tonumber(suf) then
                chapter = tonumber(suf)
                suf = suff
            end
            mode, format = head, suf
            break;
        end
    end

    if mode then
        -- process mode
        self.modes = mode == 'refs' and { 'refs' }
            or mode == 'all' and {'issue', 'offprint'}
            or mode == 'off' and { 'offprint' }
            or mode == 'vol' and { 'issue' }
            or mode == 'bare' and { 'bare' }
            or mode == 'book' and { 'book' }
        -- choose format
        if format == '' then
            self.formats = mode == 'refs' and {}
                or mode == 'all' and {'html', 'pdf'}
                or mode == 'off' and {'html'}
                or {'pdf'}
        elseif format == 'all' then
            self.formats = mode == 'all' and {'html', 'pdf'}
                or mode == 'off' and {'html', 'pdf'}
                or {'pdf'}
        else
            self.formats = { format }
        end
        -- chose chapters, default all
        if mode == 'all' or mode == 'off' then
            if chapter then 
                self.chapters = { chapter }
            else
                self.chapters = { 0 }
            end
        end

        return args
    end

    assert(false, "I can't understand the argument: "..arg)
    return args
end

function Options:readCLargs(args)
    local arg = args[1]
    table.remove(args, 1)

    -- Flag(s)

    local flags = pandoc.List:new()
    if arg:match('^%-%-.+') then
        local flag = self:checkArg( arg:match('^%-%-(.+)'),
            FLAGS, 'Unknown flag' )
        flags:insert(flag)
    elseif arg:match('^%-.$') then
        local flag = self:checkArg( arg:match('^%-(.)'),
            SHORTFLAGS, 'Unknown flag' )
        flags:insert(flag)
    elseif arg:match('^%-.+') then
        for i = 2, #arg do
            local flag = self:checkArg( arg:sub(i,i),
                COMBINABLE_SHORTFLAGS, 'Unknown flag' )
            flags:insert(flag)
        end
    end

    if #flags > 0 then 
        for _,flag in ipairs(flags) do
            args = self:readFlag(flag, args)
        end
        return args
    end

    -- If not flag(s), try key=val

    if arg:match('^%w+=.+') then
        local key = self:checkArg(arg:match('^(%w+)=.+'),
            KEYVALS, 'Unknown key' )
        self:readKeyVal(key, arg:match('^%w+=(.+)'))
        return args
    end

    -- otherwise read plain argument

    args = self:readPlainArg(arg, args)

    return args
end

-- # Filter functions

local function getToAndOutfile(mode, format, opts, chapter)
    local basename = 'noname'
    if mode == 'issue' then
        basename = opts.collectionName or 'issue'
    elseif mode == 'book' then
        basename = opts.collectionName..'-book' or 'book'
    elseif mode == 'bare' then
        basename = opts.collectionName..'-bare' or 'bare'
    elseif mode == 'offprint' then
        local chapterFile = opts.chapterFiles and
        opts.chapterFiles[chapter] or 'noname'
        basename = getBaseFilename(chapterFile)
    end

    local ext = format == 'html' and 'html'
        or format:match('tex') and 'tex'
        or format == 'pdf' and 'pdf'
        or 'html'

    local to = format == 'html' and 'html'
    or format:match('tex') and 'latex'
    or format == 'pdf' and 'pdf'
    or 'html'

    return to, basename..'.'..ext
    
end
local function getMetadataFiles(mode, format, opts)
    local fpaths = pandoc.List:new()
    local format = format == 'html' and 'html'
        or format:match('tex') and 'latex'
        or format == 'pdf' and 'latex'
        or format == 'epub' and 'epub'
        or format == 'jats' and 'jatx'
        or nil

    for _, root in ipairs({'common', mode}) do
        for _, suffix in ipairs({'', '-'..format}) do
            local fpath = opts.templatePath(
                root..suffix..'.yaml', 'settings'
            )
            if fileExists(fpath) then
                fpaths:insert(fpath)
            end
        end
    end

    return fpaths
end

local function renderOne(mode, format, opts, chapter)
    local args = pandoc.List:new()

    args:insert(opts.pandoc)
    args:insert('-L '.. opts.templatePath('collection.lua', 'filters'))

    -- default files
    args:insert('-d '.. opts.templatePath('d_common.yaml'))
    --args:insert('-d '.. opts.templatePath('d_'..opts.system..'.yaml'))
    local modeDefaults = opts.templatePath('d_'..mode..'.yaml')
    if fileExists(modeDefaults) then 
        args:insert('-d '..modeDefaults)
    end

    -- metadata files
    args:insert('--metadata-file '..opts.collMetaData)
    for _,file in ipairs(getMetadataFiles(mode,format,opts)) do
        args:insert('--metadata-file '..file)
    end

    -- mode-specific flags
    if mode == 'bare' then
        args:insert('-M imports=false')
    elseif mode == 'offprint' then
        args:insert('-M offprint-mode='..tostring(chapter))
    end

    -- other flags
    if opts.proof then 
        args:insert('-M proofmode=true')
    end

    -- output format and filename
    local fmt, fname = getToAndOutfile(mode,format,opts,chapter)
    args:insert('-t '..fmt..' -o '..fname)

    -- source (master) file
    args:insert(opts.master)

    local cmd = table.concat(args, ' ')
    message('Running: '..cmd)
    os.execute(cmd)
end

local function render(mode, format, opts)
    local verbosity = opts.verbosity
    if mode == 'offprint' then
        for _,ch in ipairs(opts.chapters) do
            if verbosity ~= 'quiet' then 
                message('Rendering offprint '..tostring(ch)..' in format '..format)
            end
            renderOne(mode, format, opts, ch)
        end
    else
        message('Rendering '..mode..' in format '..format)
        renderOne(mode, format, opts)
    end
end

local function getCollectionName(doc)
    local name = 'untitled'
    local doi = doc.meta.doi and 
        stringify(doc.meta.doi):gsub('%d+%.%d+/','')
    return doi and doi
        or doc.meta.date 
        and 'issue'..stringify(doc.meta.date):gsub(' ','-')
        or 'untitled'
end

local function getChapterFiles(opts, doc)
    local imports = doc.meta.imports
    if not imports or not type(imports) == 'List' then return end
    local files = pandoc.List:new()
    local renderAll = opts.chapters[1] == 0 and true or false
    local chapIndices = pandoc.List:new()

    function getFile(item) 
        return (type(item) == 'Inlines' or type(item))
            and stringify(item)
            or type(item) == 'table' and item.file 
            and stringify(item.file)
            or nil
    end
    
    for i,item in ipairs(imports) do
        files:insert(getFile(item))
        if renderAll then chapIndices:insert(i) end
    end

    if renderAll then opts.chapters = chapIndices end
    opts.chapterFiles = files
    return opts

end

local function createTempCollectionMetadata(opts)
    local tmpFilemame = '_collection.yaml'
    local yaml = readFile(
        opts.templatePath('collection.yaml', 'settings')
    )
    -- Windows paths interfere with gsub
    local subs = {
        TEMPLATEFOLDER = makeNixPath(opts.templatePath()),
        DEFAULTSFILE = makeNixPath(opts.templatePath(
          'paper-in-issue-'..opts.system..'.yaml'
          )),
    }
    for pattern, str in pairs(subs) do
        yaml = yaml:gsub(pattern, str)
    end
    writeToFile(yaml, tmpFilemame)
    return tmpFilemame
end

--- renderRefs: call the refs.lua script to create reference lists for OJS
local function renderRefs(opts)
    verbose = opts.verbosity ~= 'quiet'

    -- self locate and add to path
    local selfpath = path.join({
            path.directory(debug.getinfo(2, "S").source:sub(2)),
            '?.lua'
    })
    package.path = package.path .. ';' .. selfpath
    if verbose then
        message('Printing out references lists for each article')
    end
    require('refs')
end

---main
---@param args CLargs
local function main(args)
    opts = Options:new(args)

    -- if we have modes other than 'refs', prepare rendering artefacts
    if #opts.modes > 1 or opts.modes[1] ~= 'refs' then
        -- read and parse the master file
        local doc = pandoc.read(readFile(opts.master),
            'markdown',
            {standalone = true}
        )
        -- create a temp collection metadata file
        opts.collMetaData = createTempCollectionMetadata(opts)

        -- get issue name, chapter file names
        opts.collectionName = getCollectionName(doc)
        opts = getChapterFiles(opts, doc)

    end

    -- loop over modes and do jobs
    for _,mode in ipairs(opts.modes) do
        if mode == 'refs' then
            renderRefs(opts)
        else
            for _,format in ipairs(opts.formats) do

                -- html is offprint only
                if format ~= 'html' or mode == 'offprint' then 
                    render( mode, format, opts )
                end
                
            end
        end
    end
end

-- lua's command line arguments are in the `arg` table
main(arg)
