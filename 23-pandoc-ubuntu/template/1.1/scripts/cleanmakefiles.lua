--[[ cleanmakefiles.lua

Clean and recreate makefiles throughout the workhouse folder
Uses GNU `find`, MacOS / Linux / WSL only

]]

path = pandoc.path
list_directory = pandoc.system.list_directory

TEMPLATE_DIR = path.join{'template', '1.1'}

MAKEFILE_NAMES = { 'Makefile', 'make.bat', 'generatemakefile.sh' }

-- in case we need to regenerate these
MAKE_SH = [[#! /bin/sh
if [ -f "../../template/1.1/scripts/make.lua" ]; then
    maker="../../template/1.1/scripts/make.lua"
elif [ -f "../../../template/1.1/scripts/make.lua" ]; then
    maker="../../../template/1.1/scripts/make.lua"
fi
if [ -n $maker ]; then
    pandoc lua $maker $@
else
    echo "Can't find the make.lua script."
fi
]]

MAKE_BAT = [[pandoc lua SCRIPTPATH %*
]]

-- split string by separator into a table
-- option to skip empties
local function split(str, sep, noEmpties)
    local noEmpties = noEmpties or false
    local sep = sep or ","
    local result = {}
    local i = 1
    for c in (str..sep):gmatch("(.-)"..sep) do
        if not (noEmpties and c == '') then
            result[i] = c
            i = i + 1
        end
    end
    return result
end

---writeToFile: write string to file.
---@param contents string file contents
---@param filepath string file path
---@return nil | string status error message
function writeToFile(contents, filepath)
  local f = io.open(filepath, 'w')
  if f ~= nil then 
    assert(f:write(contents), 'Cannot write file '..filepath)
	f:close()
  else
    return 'File not written'
  end
end

local function eraseFiles(files)
    for _,file in ipairs(files) do 
        assert(os.remove(file))
    end
end

local function getStdOutLines(cmd)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    s = s:gsub('[\n\r]+', '\n')
    return s ~= '' and split(s, '\n', true) 
    or {}
end

local function findDialoaSubdirs(dirpath, mindepth, maxdepth)
    if not maxdepth then maxdepth = mindepth end
    if not mindepth then mindepth, maxdepth = 1, 2 end
    local cmd = 'find '..dirpath
        ..' -mindepth '..tostring(mindepth)
        ..' -maxdepth '..tostring(mindepth)
        ..' -type d '
    return getStdOutLines(cmd)
end

local function getDialoaDirsByLevel(basedir)
    dirs1, dirs2 = pandoc.List:new(), pandoc.List:new()
    for _,entry in ipairs(list_directory(basedir)) do
        if entry:match('^202%d$') or entry:match('^processing$') then

            dirs1:extend(findDialoaSubdirs(path.join{basedir, entry}, 1))
            dirs2:extend(findDialoaSubdirs(path.join{basedir, entry}, 2))

        end
    end

    -- remove '.RProj' and the like
    local cleaner = function (el) 
        if not el:match('/%.Rproj%.%w+') then
            return true
        else
            return false
        end
    end
    dirs1:filter(cleaner)
    dirs2:filter(cleaner)    

    return dirs1, dirs2
end

local function createBatchfiles(dirs1, dirs2, makebat)
    makebat = makebat or MAKE_BAT

    -- create make.bat in level 1 folders, level 2 folders
    local scriptPath = path.join {'..', '..', TEMPLATE_DIR, 'scripts', 'make.lua'}
    local makeb = makebat:gsub('SCRIPTPATH', scriptPath)
    for _, dir in ipairs(dirs1) do
        writeToFile(makeb, path.join{dir, 'make.bat'})
    end
    scriptPath = path.join {'..', scriptPath}
    local makeb = makebat:gsub('SCRIPTPATH', scriptPath)
    for _, dir in ipairs(dirs2) do
        writeToFile(makeb, path.join{dir, 'make.bat'})
    end

end

local function createBashLinks(dirs1, dirs2)
    local scriptPath = path.join {'..', '..', TEMPLATE_DIR, 'scripts', 'make.sh'}
    for _,dir in ipairs(dirs1) do
        local symb = path.join {dir, 'make.sh'}
        local cmd = 'ln -sf '..scriptPath..' '..symb
        print(symb, '->', scriptPath)
        os.execute(cmd)
    end
    scriptPath = path.join {'..', scriptPath}
    for _,dir in ipairs(dirs2) do
        local symb = path.join {dir, 'make.sh'}
        local cmd = 'rm -f '..symb
        os.execute(cmd)
        local cmd = 'ln -s '..scriptPath..' '..symb
        print(scriptPath, '<-', symb)
        os.execute(cmd)
    end
end

local function createMakes(basedir, makebat)
    -- get Level 1 and Level 2 dir lists
    dirs1, dirs2 = getDialoaDirsByLevel(basedir)

    createBatchfiles(dirs1, dirs2, makebat)

    createBashLinks(dirs1, dirs2)

end

local function findMakefilesIn(dirpath)
    local list = pandoc.List:new()
    local baseCmd = 'find '..dirpath..' -type f -name '
    for _,name in ipairs(MAKEFILE_NAMES) do
        local cmd = baseCmd..'"'..name..'"'
        list:extend(getStdOutLines(cmd))
    end
    
    return list
end


--- erase makefiles in:
--- `202x` subfolders and subsubfolders
--- `processing` subfolders and subsubfolders
local function eraseMakefiles(basedir)
    files = pandoc.List:new()
    for _,entry in ipairs(list_directory(basedir)) do
        if entry:match('^202%d$') or entry:match('^processing$') then

            files:extend(findMakefilesIn(path.join{basedir, entry}))

        end
    end

    -- display list
    for _,file in ipairs(files) do
        print(file)
    end
    print('Erase these '..tostring(#files)..' files, are you sure? (Y/N)')
    local reply = io.read()
    if reply == 'Y' then
        eraseFiles(files)
    end    

end


local function main(arg)
    if arg[1] == 'createall' then
        if arg[2] then
            createMakes(arg[2],arg[3])
        else
            print('Need give the path to the workhouse folder. Use with care.')
        end         
    elseif arg[1] == 'eraseall' then
        if arg[2] then
            eraseMakefiles(arg[2])
        else
            print('Need give the path to the workhouse folder. Use with care.')
        end
    end
end

main(arg)
        