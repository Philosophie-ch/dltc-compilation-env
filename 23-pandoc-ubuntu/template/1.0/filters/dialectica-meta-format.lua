--[[-- Dialectica issue format filters: Prepare front matter elements
 based on an issue's master metadata.

Uses the metadata fields:
- templatefolder
- ISSN, alias issn
- ISBN, alias isbn
- volume
- issue
- first-page
- editorialboard
- journaleditors
- revieweditors
- editorialcommittee
- consultingboard
- indexingservices

Generates the LaTeX commands:

- \printtitle
- \printauthor
- \printISSNline 'ISSN number' or baseline empty line
- \printISBNline
- \printvolume
- \printissue
- \printdate
- \printdoi
- \printcovertitle
- \printinnertitle
- \setstartingpage
- \editorialboard
- etc. for committe lists and indexing services
- \logoesap{width}{height}{color}, e.g. \logoesap{55pt}{!}{black}
- \logoopenaccess{width}{height}

]]
--

local stringify = pandoc.utils.stringify
local path = require('pandoc.path')
-- settings
local settings = {
	default_special_issue_title = 'Special issue',
	edited_by = 'edited by'
}


function Meta (meta)

	local latex_commands = ''
	add_latex = function(command)
		latex_commands = latex_commands .. command
	end

	-- title, author (for offprints)
	local title_tex = ''
	if meta['title-tex'] then
		title_tex = stringify(meta['title-tex'])
	elseif meta.title then
		title_tex = stringify(meta.title)
	end
	add_latex('\\newcommand{\\printtitle}{'..title_tex..'}\n')

	local authors_str = ''
	if meta.author then
		for i = 1, #meta.author do
			authors_str = authors_str .. stringify(meta.author[i].name)
			if i < #meta.author then
				if i < #meta.author-1 then
					authors_str = authors_str .. ', '
				else
					authors_str = authors_str .. ' and '
				end
			end
		end
	end
	add_latex('\\newcommand{\\printauthor}{'..authors_str..'}\n')

	-- volume, issue and date
	for _,key in ipairs({'volume','issue', 'date'}) do
		if meta[key] then
			add_latex('\\newcommand*{\\print'..key..'}{'
					..stringify(meta[key])..'}\n')
		end
	end

	-- titlepage elements
	-- if not special issue, add empty line on cover and inner title
	-- if special issue, prepare cover title and inner title
	if not meta['special-issue'] then
		add_latex('\\newcommand{\\printcovertitle}{\\vskip 18pt}\n')
		add_latex('\\newcommand{\\printinnertitle}{\\vskip 18pt}\n')
	else
		-- for special issue, get title and editors
		local title_tex = ''
		if meta['issue-title-tex'] then
			title_tex = stringify(meta['issue-title-tex'])
		elseif meta['issue-title'] then
			title_tex = stringify(meta['issue-title'])
		else
			title_tex = settings.default_special_issue_title
		end
		local editors_str = ''
		if meta.editor then
			if meta.editor.t ~= 'MetaList' then 
				meta.editor = pandoc.MetaList(meta.editor)
			end
			for i = 1, #meta.editor do
				editors_str = editors_str .. stringify(meta.editor[i].given)
												.. ' ' .. stringify(meta.editor[i].family)
				if i < #meta.editor then
					if i < #meta.editor-1 then
						editors_str = editors_str .. ', '
					else
						editors_str = editors_str .. ' and '
					end
				end
			end
		end
		if editors_str ~= '' then
			add_latex(
				'\\newcommand{\\printcovertitle}{\n'
				..'  \\usekomafont{covertitle} '..title_tex..'\n'
				..'  \\vskip 12pt'
				..'  \\usekomafont{covereditedby}'..settings.edited_by.. '\n'
				..'  \\usekomafont{covereditor}'..editors_str..'\n'
				..'}\n'
			)
			add_latex(
				'\\newcommand{\\printinnertitle}{\n'
				..'  \\usekomafont{innertitle} '..title_tex..'\n'
				..'  \\vskip 12pt'
				..'  \\usekomafont{innereditedby}'..settings.edited_by.. '\n'
				..'  \\usekomafont{innereditor}'..editors_str..'\n'
				..'}\n'
			)
		else
			add_latex(
				'\\newcommand{\\printcovertitle}{\n'
				..'  \\usekomafont{covertitle} '..title_tex..'\n'
				..'  \\vskip 18pt'
				..'}\n'
			)
			add_latex(
				'\\newcommand{\\printinnertitle}{\n'
				..'  \\usekomafont{innertitle} '..title_tex..'\n'
				..'  \\vskip 18pt'
				..'}\n'
			)
		end
	end

	-- Logos
	local logos = {
		'esap-logo.tex', 'openaccess-logo-platinum.tex', 'cc-by-logo.tex',
		'cc-by-inline-logo.tex'
	}
	local templatefolder = ''
	if meta.templatefolder then 
		templatefolder = stringify(meta.templatefolder)
	end
	for _,logo in ipairs(logos) do
		add_latex('\\input{'..path.join({templatefolder, 'media', logo})
			..'}\n')
	end

	--- first page
	-- use the source's first-page in offprint mode, 
	-- otherwise the issue
	local starting_page = 0
	-- if meta['offprint-mode'] then
	-- 	local index = tonumber(stringify(meta['offprint-mode']))
	-- 	if imports[i]['first-page'] then
	-- 		starting_page = tonumber(stringify(meta['first-page'])) - 1
	-- 	end
	if meta['first-page'] ~= nil then
		starting_page = tonumber(stringify(meta['first-page'])) or 1
		starting_page = starting_page - 1
	end
	if starting_page ~= 0 then
		add_latex('\\newcommand*{\\setstartingpage}{\\setcounter{page}{' 
			.. tostring(starting_page) .. '}}\n'
		)
	else
		add_latex('\\newcommand*{\\setstartingpage}{}\n')
	end

	-- ISSN and ISBN
	-- normalize meta
	for _,key in ipairs({'issn', 'isbn'}) do
		if meta[key] then
			meta[string.upper(key)] = meta[key]
		end
	end
	-- create LaTeX commands
	for _,key in ipairs({'ISSN', 'ISBN'}) do
		local command = '\\vskip \\baselineskip'
		if meta[key] then 
			command = key .. ' ' .. stringify{meta[key]}
		end
		add_latex('\\newcommand*{\\print'..key..'line}{'..command..'}\n'
			)
	end

	-- DOI
	local doi = ''
	if meta.doi then
		doi = stringify(meta.doi)
	end
	add_latex('\\newcommand*{\\printdoi}{\\href{https://doi.org/'..doi..'}'
		..'{'..doi..'}}\n')

	-- LISTS: editorial board and committees, indexing services

	local linelists = {'editorialboard','journaleditors','revieweditors'}
	local commalists = {'editorialcommittee','consultingboard',
					'indexingservices'}

	-- function to generate LaTeX linebreak-separated lists
	-- @param list a Pandoc element
	-- @param separator string to separate items
	latex_list = function(list, separator)
		if list.t ~= 'MetaList' then
			return stringify(list)
		end
		result = ''
		for i = 1, #list do
			result = result .. stringify(list[i]) 
			if i < # list then 
				result = result .. separator
			end
		end
		return result
	end

	for _,key in ipairs(linelists) do
		if meta[key] then
		add_latex(
			'\\newcommand{\\' .. key .. '}{%\n'
			.. latex_list(meta[key], ' \\\\\n')
			.. '%\n}\n'
			)
		end
	end

	for _,key in ipairs(commalists) do
		if meta[key] then
			add_latex(
				'\\newcommand{\\' .. key .. '}{%\n'
				.. latex_list(meta[key], ', ')
				.. '%\n}\n'
				)
		end
	end

	if not meta['header-includes'] 
		or meta['header-includes'].t ~= 'MetaList' then
			meta['header-includes'] = pandoc.MetaList({meta['header-includes']})
	end
	meta['header-includes']:insert(1, pandoc.MetaBlocks(
			pandoc.RawBlock('latex', latex_commands)
		))

	return meta

end