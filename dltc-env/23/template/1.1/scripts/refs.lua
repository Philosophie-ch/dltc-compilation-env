--[[-- refs.lua generate reference lists for each article
 in an issue.

Run with pandoc from the issue folder:

    pandoc lua ../../template/1.1/scripts/refs.lua 

--]]

-- # Global variable
local Setup = {
    sources = {},
    bib_files = {},
    template_dir = ''
}

-- # Helper functions

-- ## pandoc utils
local metatype = pandoc.utils.type
local stringify = pandoc.utils.stringify
local citeproc = pandoc.utils.citeproc

-- ## File functions

local system = pandoc.system
local path = pandoc.path

---fileExists: checks whether a file exists
local function fileExists(filepath)
  local f = io.open(filepath, 'r')
  if f ~= nil then
    io.close(f)
    return true
  else 
    return false
  end
end

---makeAbsolute: make filepath absolute
---@param filepath string file path
---@param root string|nil if relative, use this as root (default working dir) 
local function makeAbsolute(filepath, root)
  root = root or system.get_working_directory()
  return path.is_absolute(filepath) and filepath
    or path.join{ root, filepath}
end

---folderExists: checks whether a folder exists
local function folderExists(folderpath)

  -- the empty path always exists
  if folderpath == '' then return true end

  -- normalize folderpath
  folderpath = folderpath:gsub('[/\\]$','')..path.separator
  local ok, err, code = os.rename(folderpath, folderpath)
  -- err = 13 permission denied
  return ok or err == 13 or false
end

---ensureFolderExists: create a folder if needed
local function ensureFolderExists(folderpath)
  local ok, err, code = true, nil, nil

  -- the empty path always exists
  if folderpath == '' then return true, nil, nil end

  -- normalize folderpath
  folderpath = folderpath:gsub('[/\\]$','')

  if not folderExists(folderpath) then
    ok, err, code = os.execute('mkdir '..folderpath)
  end

  return ok, err, code
end

---writeToFile: write string to file.
---@param contents string file contents
---@param filepath string file path
---@return nil | string status error message
local function writeToFile(contents, filepath)
  local f = io.open(filepath, 'w')
	if f then 
	  f:write(contents)
	  f:close()
  else
    return 'File not found'
  end
end

---readFile: read file as string.
---@param filepath string file path
---@return string contents or empty string if failure
local function readFile(filepath)
	local contents
	local f = io.open(filepath, 'r')
	if f then 
		contents = f:read('a')
		f:close()
	end
	return contents or ''
end

-- stripExtension: strip filepath of the filename's extension
---@param filepath string file path
---@param extensions string[] list of extensions, e.g. {'tex', 'latex'}
---  if not provided, any alphanumeric extension is stripped
---@return string filepath revised filepath
local function stripExtension(filepath, extensions)
  local name, ext = path.split_extension(filepath)
  ext = ext:match('^%.(.*)')

  if extensions then
    extensions = pandoc.List(extensions)
    return extensions:find(ext) and name
      or filepath
  else
    return name
  end
end

-- # Core functions

local function readMaster(file_contents)
    local doc = pandoc.read(file_contents, 'markdown', {
        standalone = true,
    })
    local templatefolder = stringify(doc.meta.templatefolder) or ''
    local imports = pandoc.List:new()

    if doc.meta.imports then
        for _,item in ipairs(doc.meta.imports) do
            if metatype(item) == 'string' 
                or metatype(item) == 'Inlines' then
                imports:insert(stringify(item))
            elseif metatype(item) == 'table' and item.file then
                imports:insert(stringify(item.file))
            end
        end
    end

    return {
        sources = imports,
        template_dir = templatefolder,
    }

end

local function findBibfiles(setup)
    local result = pandoc.List:new()
    for _,source in ipairs(setup.sources) do
        local doc = pandoc.read(readFile(source),
            'markdown', { standalone = true }
        )
        local bib_file = doc.meta.bibliography
            and path.directory(source)
            .. path.separator
            .. stringify(doc.meta.bibliography)
            or ''
        result:insert(bib_file)
    end
    return result
end

-- Plain citeproc output inserts some newlines within entries
-- and two newlines between them,
-- We need to no newlines witin entries and one between.
local function removeNewlines(str)
    return str:gsub('\n\n', 'NEWLINE'):gsub('\n',''):gsub('NEWLINE','\n')
end

local function createRefFiles(setup)
    for i = 1, #setup.sources do
        local source = setup.sources[i]
        local bibfile = setup.bib_files[i]
        local name, doc 
        if bibfile ~= '' then
          name = stripExtension(path.filename(source), {'md'})
          doc = pandoc.read(
              readFile(bibfile), 'bibtex',
              { standalone = true })
          local output = ''

          doc.meta.csl = setup.template_dir
              .. '/csl/apa.csl'
          doc = citeproc(doc)
          output = removeNewlines(
              pandoc.write(doc, 'plain')
          )

          print('Creating '..name..'.bib.txt')
          writeToFile(output, name..'.bib.txt')
        end
    end
    print('Done.')
end


-- # main
if not fileExists('master.md') then
    print('ERROR: master.md file not found')
end

Setup = readMaster(readFile('master.md'))
Setup.bib_files = findBibfiles(Setup)
createRefFiles(Setup)
