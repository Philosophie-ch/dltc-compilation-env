--[[-- # Makemakefile - Makefile builder for dialectica issues

LEGACY - outdated since March 2023

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@copyright 2022 Julien Dutant
@license MIT - see LICENSE file for details.
@release 0.1

Usage

pandoc -L makemakefile.lua master.md -o Makefile -t plain
pandoc -L makemakefile.lua master.md -o make.bat -t plain

]]

local type = '' -- 'Makefile' or 'make.bat'
local nix_preamble = [[
MD_FILES = $(wildcard */*.md)
BIB_FILES = $(wildcard */*.bib)
SVG_FILES = $(wildcard */*.svg)
STYLE = ../../template/1.1
proof = false # use `make off2 proof=true` to get a proof version

# verbosity
ifeq ($(VERBOSITY), INFO)
	VERBFLAG = --verbose
else
ifeq ($(VERBOSITY), ERROR)
	VERBFLAG = --quiet
endif
endif

# Pick master file depending on the system
ifeq ($(OS),Windows_NT)
    MASTER = master-win.md
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
	    MASTER = master-win.md
    endif
    ifeq ($(UNAME_S),Darwin)
	    MASTER = master-macos.md
    else
	    MASTER = master-nix.md
    endif
endif

# default target
.PHONY: pdf
pdf: volpdf

# Targets to regenerate -win and -nix masters
master-win.md: master.md
	@cat master.md | sed 's/paper-in-issue.yaml/paper-in-issue-win.yaml/'\
	 > master-win.md
	@echo Windows master file regenerated from master.md 

master-nix.md: master.md
	@cat master.md | sed 's/paper-in-issue.yaml/paper-in-issue-nix.yaml/'\
	> master-nix.md
	@echo Linux master file regenerated from master.md

master-macos.md: master.md
	@cp master.md master-macos.md

.PHONY: cleanmasters
cleanmasters: 
	@rm -f master-win.md master-nix.md master-macos.md

# Main targets
.PHONY: refs
refs: 
	@pandoc lua $(STYLE)/scripts/refs.lua

.PHONY: tex
tex: voltex

.PHONY: latex
latex: voltex

.PHONY: volpdf
volpdf: make_volpdf
	@make cleanmasters

.PHONY: voltex
voltex: make_voltex
	@make cleanmasters

.PHONY: book
book: bookpdf

.PHONY: bookpdf
bookpdf: make_bookpdf
	@make cleanmasters

.PHONY: booktex
booktex: make_booktex
	@make cleanmasters

.PHONY: barepdf
barepdf: bare

.PHONY: bare
bare: make_bare
	@make cleanmasters

.PHONY: baretex
baretex: make_baretex
	@make cleanmasters

.PHONY: make_volpdf
make_volpdf: $(MASTER) $(MD_FILES) $(BIB_FILES) $(SVG_FILES)
	@echo Generating the issue in PDF: ISSUEPDF
	@pandoc -L $(STYLE)/filters/collection.lua $(MASTER) -d $(STYLE)/issue.yaml \
	-o ISSUEPDF $(VERBOSE)

.PHONY: make_voltex
make_voltex: $(MASTER) $(MD_FILES) $(BIB_FILES)
	@echo Generating the issue TeX file: ISSUETEX
	@pandoc -L $(STYLE)/filters/collection.lua $(MASTER) -d $(STYLE)/issue.yaml \
	-o ISSUETEX $(VERBOSE)

.PHONY: make_bookpdf
make_bookpdf: $(MASTER) $(MD_FILES) $(BIB_FILES) $(SVG_FILES)
	@echo Generating the issue in PDF: BOOKPDF
	@pandoc -L $(STYLE)/filters/collection.lua $(MASTER) -d $(STYLE)/book.yaml \
	-o BOOKPDF $(VERBOSE)

.PHONY: make_booktex
make_booktex: $(MASTER) $(MD_FILES) $(BIB_FILES)
	@echo Generating the issue TeX file: BOOKTEX
	@pandoc -L $(STYLE)/filters/collection.lua $(MASTER) -d $(STYLE)/book.yaml \
	-o BOOKTEX $(VERBOSE)

.PHONY: make_bare
make_bare: $(MASTER) $(MD_FILES) $(BIB_FILES) $(SVG_FILES)
	@echo Generating a bare issue PDF
	@pandoc -L $(STYLE)/filters/collection.lua $(MASTER) -d $(STYLE)/issue.yaml \
	-M imports=false -o bare.pdf $(VERBOSE)

.PHONY: make_baretex
make_baretex: $(MASTER) $(MD_FILES) $(BIB_FILES)
	@echo Generating a bare issue TeX file
	@pandoc -L $(STYLE)/filters/collection.lua $(MASTER) -d $(STYLE)/issue.yaml \
	-M imports=false -o bare.tex $(VERBOSE)

]]
local nix_offprint = [[
.PHONY: offFILENUMBER
offFILENUMBER: make_offFILENUMBER
	@make cleanmasters

.PHONY: offFILENUMBERtex
offFILENUMBERtex: make_offFILENUMBERtex
	@make cleanmasters

.PHONY: offFILENUMBERhtml
offFILENUMBERhtml: make_offFILENUMBERhtml
	@make cleanmasters

.PHONY: make_offFILENUMBER
make_offFILENUMBER: $(MASTER) $(MD_FILES) $(BIB_FILES) $(SVG_FILES)
	@echo Generating PDF offprint FILENAMEPDF
	@pandoc -L $(STYLE)/filters/collection.lua $(MASTER) -d $(STYLE)/offprint.yaml \
	-o FILENAMEPDF -M offprint-mode=FILENUMBER -M proofmode=$(proof) $(VERBOSE)

.PHONY: make_offFILENUMBERtex
make_offFILENUMBERtex: $(MASTER) $(MD_FILES) $(BIB_FILES) $(SVG_FILES)
	@echo Generating TeX offprint FILENAMETEX
	@pandoc -L $(STYLE)/filters/collection.lua $(MASTER) -d $(STYLE)/offprint.yaml \
	-o FILENAMETEX -M offprint-mode=FILENUMBER -M proofmode=$(proof) $(VERBOSE)

.PHONY: make_offFILENUMBERhtml
make_offFILENUMBERhtml: $(MASTER) $(MD_FILES) $(BIB_FILES) $(SVG_FILES)
	@echo Generating HTML offprint FILENAMEHTML
	@pandoc -L $(STYLE)/filters/collection.lua $(MASTER) -d $(STYLE)/offprint.yaml \
	-o FILENAMEHTML -M offprint-mode=FILENUMBER -M proofmode=$(proof) $(VERBOSE)

]]
local cleanmasters = [[
	@make cleanmasters

]]

--- Meta: check the parameters (called before Pandoc)
function Meta(meta)
  -- output file must be: "Makefile" or "make.bat"
  -- output type must be: plain
  -- source file must have: imports field
  type = 'Makefile'
end

--- Pandoc: generate the makefile
function Pandoc(doc)
	if type == 'Makefile' then

		--- prepare list of dependencies for the `all` and `offprints` targets
		local dep, tex_dep, html_dep = '', '', ''
		local result = pandoc.Pandoc({},{})
		local function get_doi(doc) 
			if doc.meta.doi then
				_,__, doi = pandoc.utils.stringify(doc.meta.doi):find('/(.*)$')
				return doi ~= '' and doi or nil
			end
		end
		local filename = get_doi(doc) or 'issue'

		nix_preamble = nix_preamble:gsub('ISSUEPDF', filename .. '.pdf')
		nix_preamble = nix_preamble:gsub('ISSUETEX', filename .. '.tex')
		nix_preamble = nix_preamble:gsub('BOOKPDF', filename .. '-book.pdf')
		nix_preamble = nix_preamble:gsub('BOOKTEX', filename .. '-book.tex')

		result.blocks:insert(pandoc.Para(pandoc.Str(nix_preamble)))

		-- offprint file names

		if doc.meta.imports and pandoc.utils.type(doc.meta.imports) == 'List' then
			for i,import in ipairs(doc.meta.imports) do


				local filepath, file = '', ''
				if pandoc.utils.type(import) == 'table' and import.file then
					filepath = pandoc.utils.stringify(import.file)
				elseif pandoc.utils.type(import) == 'Inlines' then
					filepath = pandoc.utils.stringify(import)
				elseif pandoc.utils.type(import) == 'string' then
					filepath = import
				end

		        if filepath ~='' then

		        	local filename = pandoc.path.filename(filepath):gsub("%.md$", '')

		        	local str = nix_offprint:gsub('FILENUMBER', tostring(i))
		        	str = str:gsub('FILENAMEPDF', filename .. '.pdf')
		        	str = str:gsub('FILENAMETEX', filename .. '.tex')
		        	str = str:gsub('FILENAMEHTML', filename .. '.html')

		        	result.blocks:insert(pandoc.Para(pandoc.Str(str)))

		        	dep = dep .. ' make_off' .. tostring(i)
		        	tex_dep = tex_dep .. ' make_off' .. tostring(i) .. 'tex'
		        	html_dep = html_dep .. ' make_off' .. tostring(i) .. 'html'

		        end

			end

		end

		-- insert 'all(tex)' and 'offprints(tex)' targets
	    result.blocks:insert(pandoc.Para(
	    	pandoc.Str('.PHONY: all\n'
				..'all: make_volpdf' .. dep ..'\n'.. cleanmasters)))
	    result.blocks:insert(pandoc.Para(
	    	pandoc.Str('.PHONY: alltex\n'
				..'alltex: make_voltex' .. tex_dep ..'\n'.. cleanmasters)))
	    result.blocks:insert(pandoc.Para(
	    	pandoc.Str('.PHONY: offprints\n'
				..'offprints:' .. dep ..'\n'.. cleanmasters)))
	    result.blocks:insert(pandoc.Para(
	    	pandoc.Str('.PHONY: offprintstex\n'
				..'offprintstex:' .. tex_dep ..'\n'.. cleanmasters)))
	    result.blocks:insert(pandoc.Para(
	    	pandoc.Str(
				'.PHONY: offprintshtml\n'
				..'offprintshtml:' .. html_dep ..'\n'.. cleanmasters)))

		return result
	end
end
