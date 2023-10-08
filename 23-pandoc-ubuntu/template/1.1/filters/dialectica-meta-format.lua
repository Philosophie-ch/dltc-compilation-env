--[[-- Dialectica issue format filters: Prepare front matter elements
 based on an issue's master metadata.

Uses the metadata fields:
- templatefolder (Unix-style path: /path/to/template/)
- ISSN, alias issn
- ISBN, alias isbn
- volume
- issue
- date
- first-page
- last-page
- editorialboard
- journaleditors
- revieweditors
- editorialcommittee
- consultingboard
- indexingservices
- sponsors
- abstract-text (Dublin-Core metadata description can't handle e.g. MathJax spans)

Generates the metadata variables:
- title-meta, author-meta: for PDF title and author properties

Generates the variables (for HTML):
- html-printauthor
- dc.type, dc.articleType, dc.source, dc.sourceURI, dc.rights

Generates the LaTeX commands:

- \printtitle (plain title)
- \printsubtitle
- \printfulltitle (title + subtitle)
- \printauthor
- \printsignature (author block at the end of papers)
- \printoffprinttitle (title for the offprint cover, may include linebreaks)
- \printoffprintsubtitle
- \setkomafont{offprinttitle}{...}
- \setkomafont{offprintsubtitle}{...} (\Huge, \huge...)
- \printISSNline 'ISSN number' or baseline empty line
- \printISBNline
- \printvolume
- \printissue
- \printdate
- \printyear
- \printdoi
- \printdoiurl
- \printcovertitle (for issue cover title, empty in normal issues)
- \printinnertitle (for issue inner title title)
- \printcitation (for the offprint cover, with 'early view' mode)
- \abovecovertitleskip (adjust spacing for 'early view' mode)
- \belowcitationskip (adjust spacing for 'early view' mode)
- \setstartingpage
- \setissuestarting page (template uses it if article mtadata "collection-first-import" is true)
- \printpagerange (offprint mode only)
- \editorialboard
- etc. for committe lists, indexing services, sponsors
- \logoesap{width}{height}{color}, e.g. \logoesap{55pt}{!}{black}
- \logoopenaccess{width}{height}

Note

- \ORCIDid is defined in the common-koma preamble

]]
--

local stringify = pandoc.utils.stringify
local path = require('pandoc.path')
-- settings
local settings = {
	default_special_issue_title = 'Special issue',
	edited_by = 'edited by',
	last_sep = '&',
	last_sep_tex = '\\&',
}
local offprint_autoresize = {
	title = {
		length = 30,
		new_size = '\\huge'
	},
	subtitle = {
		length = 40,
		new_size = '\\Large'
	}
} 

-- # Helper functions

--- type: pandoc-friendly type function
-- pandoc.utils.type is only defined in Pandoc >= 2.17
-- if it isn't, we extend Lua's type function to give the same values
-- as pandoc.utils.type on Meta objects: Inlines, Inline, Blocks, Block,
-- string and booleans
-- Caution: not to be used on non-Meta Pandoc elements, the
-- results will differ (only 'Block', 'Blocks', 'Inline', 'Inlines' in
-- >=2.17, the .t string in <2.17).
local type = pandoc.utils.type or function (obj)
        local tag = type(obj) == 'table' and obj.t and obj.t:gsub('^Meta', '')
        return tag and tag ~= 'Map' and tag or type(obj)
    end

--- isTextContent: check that meta element is Pandoc text
function isTextContent(elem)
	return type(elem) == 'Inlines' or type(elem) == 'Blocks'
end

--- latexify: convert Pandoc text to LaTeX
---@param elem Inlines|Blocks
---@return string result LaTeX code
local latexify = function (elem)
	-- pandoc.Pandoc needs a Block(s) argument
	-- wrap Inlines list into a table (Block)
	elem = type(elem) == 'Inlines' and {elem} or elem
	return pandoc.write(pandoc.Pandoc(elem), 'latex')
end

-- latexListify: generate LaTeX linebreak-separated list
---@param list a Pandoc element
---@param separator string to separate items
function latexListify (list, separator)
	if type(list) ~= 'List' then
		return latexify(list)
	end
	result = ''
	for i = 1, #list do
		result = result .. latexify(list[i]) 
		if i < # list then 
			result = result .. separator
		end
	end
	return result
end


-- # Filter


function metaformat(meta)

	local latexCommands = ''
	addLaTeX = function(command)
		latexCommands = latexCommands .. command
	end

	-- title, subtitle, author (for offprints)
	-- \print(sub)title: plain text title
	-- \offprint(sub)title: only on the offprint cover, may include linebreaks
	-- (sub)title-cover sets the latter if present, otherwise (sub)title-latex
	-- set `offprint(sub)title` koma font sizes if offprint(sub)title-tex-size is used

	-- TITLE AND SUBTITLE

	-- title (PDF properties)
	if not meta['title-meta'] then
		meta['title-meta'] = meta.title and stringify(meta.title) or ''
	end

	-- title and subtitle (latex)
	for _,key in ipairs({'title','subtitle'}) do
		local plain, tex = '', ''
		local texkey = key..'-cover'
		local alttexkey = key..'-latex'
		local sizekey = key..'-cover-size'
		if meta[key] and isTextContent(meta[key]) then
			plain = latexify(meta[key])
			if meta[texkey] and isTextContent(meta[texkey]) then
				tex = latexify(meta[texkey])
			elseif meta[alttexkey] and isTextContent(meta[alttexkey]) then
				tex = latexify(meta[alttexkey])
			else
				tex = plain
			end
		end
		addLaTeX('\\newcommand{\\print'..key..'}{'..plain..'}\n')
		addLaTeX('\\newcommand{\\printoffprint'..key..'}{'..tex..'}\n')

		-- smaller font for long titles
		if meta[sizekey] and isTextContent(meta[sizekey]) then
			addLaTeX('\\setkomafont{offprint'..key..'}{'
				.. latexify(meta[sizekey]) 
			..'}\n')
		elseif pandoc.text.len(plain) > offprint_autoresize[key].length then
			addLaTeX('\\setkomafont{offprint'..key..'}{'
			.. offprint_autoresize[key].new_size ..'}\n')
		end
	end

	-- full title
	if meta['subtitle'] and isTextContent(meta['subtitle']) then
		local fulltitle, separator = ''
		if meta['title'] and isTextContent(meta['title']) then
			fulltitle = latexify(meta['title'])
		end
		if fulltitle ~= '' and 
			fulltitle:sub(-1, -1):match('[%?%!]') then
			separator = ' '
		else
			separator = ': '
		end
		fulltitle = fulltitle..separator..latexify(meta['subtitle'])
		addLaTeX('\\newcommand{\\printfulltitle}{'..fulltitle..'}')
	else
		addLaTeX('\\newcommand{\\printfulltitle}{\\printtitle}')
	end

	-- AUTHOR

	-- author for offprints (latex, pdf property, html)
	local authors_str_tex, authors_str_html = '', ''
	if meta.author then
		for i = 1, #meta.author do
			if meta.author[i].name then
				local author = stringify(meta.author[i].name)
				authors_str_html = authors_str_html .. author
				authors_str_tex = authors_str_tex .. author
			end
			if i < #meta.author then
				if i < #meta.author-1 then
					authors_str_html = authors_str_html .. ', '
					authors_str_tex = authors_str_tex .. ', '
				else
					authors_str_html = authors_str_html..' '..settings.last_sep..' '
					authors_str_tex = authors_str_tex..' '..settings.last_sep_tex..' '
				end
			end
		end
	end
	meta['html-printauthor'] = authors_str_html
	addLaTeX('\\newcommand{\\printauthor}{'..authors_str_tex..'}\n')
	if not meta['author-meta'] then
		meta['author-meta'] = authors_str_html
	end

	-- check that we have an email for the corresponding author
	if meta.author then
		meta.author = meta.author:map(function(author)
			if author.correspondence and (not author.email
			or stringify(author.email) == '') then
				author.email = pandoc.Emph({pandoc.Str('no email provided')})
			end
			return author
		end
		)
	end

	-- volume, issue, date
	for _,key in ipairs({'volume','issue', 'date'}) do
		if meta[key] then
			addLaTeX('\\newcommand*{\\print'..key..'}{'
					..stringify(meta[key])..'}\n')
		end
	end

	-- year: extract from date
	if meta.date then
		local year = string.match(stringify(meta.date),'20%d%d$') or ''
		addLaTeX('\\newcommand*{\\printyear}{' .. year .. '}\n')
	end

	-- abstract-text
	if meta.abstract then
		meta['abstract-text'] = stringify(meta.abstract)
	end

	-- issue cover
	-- if not special issue, add empty line on cover and inner title
	-- if special issue, prepare cover title and inner title
	if not meta['special-issue'] then
		addLaTeX('\\newcommand{\\printcovertitle}{\\vskip 18pt}\n')
		addLaTeX('\\newcommand{\\printinnertitle}{\\vskip 18pt}\n')
	else
		-- for special issue, get title and editors
		local title_tex = ''
		if meta['issue-title-tex'] then
			title_tex = latexify(meta['issue-title-tex'])
		elseif meta['issue-title'] then
			title_tex = latexify(meta['issue-title'])
		else
			title_tex = settings.default_special_issue_title
		end
		local editors_str = ''
		if meta.editor then
			if type(meta.editor) ~= 'List' then 
				meta.editor = pandoc.MetaList({meta.editor})
			end
			for i = 1, #meta.editor do
				if meta.editor[i].given then
					editors_str = editors_str .. stringify(meta.editor[i].given)
						.. ' ' .. stringify(meta.editor[i].family)
				else
					editors_str = editors_str .. stringify(meta.editor[i])
				end
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
			addLaTeX(
				'\\newcommand{\\printcovertitle}{\n'
				..'  \\usekomafont{covertitle} '..title_tex..'\n'
				..'  \\vskip 12pt'
				..'  \\usekomafont{covereditedby}'..settings.edited_by.. '\n'
				..'  \\usekomafont{covereditor}'..editors_str..'\n'
				..'}\n'
			)
			addLaTeX(
				'\\newcommand{\\printinnertitle}{\n'
				..'  \\usekomafont{innertitle} '..title_tex..'\n'
				..'  \\vskip 12pt'
				..'  \\usekomafont{innereditedby}'..settings.edited_by.. '\n'
				..'  \\usekomafont{innereditor}'..editors_str..'\n'
				..'}\n'
			)
		else
			addLaTeX(
				'\\newcommand{\\printcovertitle}{\n'
				..'  \\usekomafont{covertitle} '..title_tex..'\n'
				..'  \\vskip 18pt'
				..'}\n'
			)
			addLaTeX(
				'\\newcommand{\\printinnertitle}{\n'
				..'  \\usekomafont{innertitle} '..title_tex..'\n'
				..'  \\vskip 18pt'
				..'}\n'
			)
		end
	end

	-- Front page citation (offprints)
	-- Online first value is (by order of priority):
	-- 	explicitly declared true/false
	--	or a empty or falsish `first-page`
	local onlinefirst = false
	if meta['online-first'] ~= nil then
		onlinefirst = meta['online-first'] or false
	elseif meta.onlinefirst ~= nil then
		onlinefirst = meta.onlinefirst or false
	elseif meta['first-page'] and meta['first-page'] ~= ''
		and tonumber(meta['first-page']) then
			onlinefirst = true
	end
	if meta['offprint-mode'] then
		if onlinefirst then
			addLaTeX('\\newcommand{\\printcitation}{\n'
				..'  \\fbox{\\parbox{.75\\textwidth}{'
				..'  \\raggedright\\normalfont\\normalsize\n'
				..'  \\begin{center}\\textbf{Online First}\\end{center}\n'
				.."  \\printauthor. forth. ``\\printfulltitle.'' "
				..'  \\emph{Dialectica}. doi:\\printdoi.\n'
				..'  \\begin{center}\n'
				..'     Please cite from the published version.\\\\'
				..'    Check for updates \\href{\\printdoiurl}{here}.\n'
				..'  \\end{center}\n'
				..'  }}\n'
				..'}\n'
			)
			addLaTeX('\\newcommand{\\abovecovertitleskip}{\\vskip 6pc}')
			addLaTeX('\\newcommand{\\belowcitationskip}{\\vskip 2pc}')
		else
			addLaTeX('\\newcommand{\\printcitation}{\n'
				..'  \\parbox{.75\\textwidth}{'
				..'\\raggedright\\normalfont\\normalsize\n'
				.."\\printauthor. \\printyear. ``\\printfulltitle.'' "
				..'\\emph{Dialectica} '
				..'\\printvolume (\\printissue)'
				..':~\\printpagerange. doi:\\printdoi.'
				..'\\\\}\n'
				..'}\n'
			)
			addLaTeX('\\newcommand{\\abovecovertitleskip}{\\vskip 8pc}')
			addLaTeX('\\newcommand{\\belowcitationskip}{\\vskip 3pc}')
		end

	else
		addLaTeX('\\newcommand{\\printcitation}{\\relax}')
	end


	-- Logos
	local logos = {
		'esap-logo.tex', 'openaccess-logo-platinum.tex', 'cc-by-logo.tex',
		'cc-by-inline-logo.tex'
	}
	templatefolder = meta.templatefolder and stringify(meta.templatefolder) or '' 
	for _,logo in ipairs(logos) do
		-- LaTeX requires Unix paths
		local filepath = templatefolder .. '/media/' .. logo 		
		addLaTeX('\\input{'..filepath..'}\n')
	end

	--- first page and page range
	-- in issue mode \setstartingpage must be empty
	--	we use \setissuestartingpage instead
	-- in issue mode \printpagerange is not used
	local starting_page = 0
	local ending_page = 0
	if meta['first-page'] ~= nil then
		starting_page = tonumber(stringify(meta['first-page'])) or 1
	end
	if meta['last-page'] ~= nil then
		ending_page = tonumber(stringify(meta['last-page'])) or 1
	end
	if meta['offprint-mode'] then
		if starting_page ~= 0 then
			addLaTeX('\\newcommand*{\\setstartingpage}{\\setcounter{page}{' 
				.. tostring(starting_page) .. '}}\n'
			)
		else
			addLaTeX('\\newcommand*{\\setstartingpage}{}\n')
		end
		addLaTeX('\\newcommand*{\\printpagerange}{'
			.. tostring(starting_page) .. '--'
			.. tostring(ending_page) .. '}\n')
		addLaTeX('\\newcommand*{\\setissuestartingpage}{}')
	else 
		if starting_page ~= 0 then
			addLaTeX('\\newcommand*{\\setissuestartingpage}{\\setcounter{page}{' 
				.. tostring(starting_page) .. '}}\n'
			)
		else
			addLaTeX('\\newcommand*{\\setissuestartingpage}{}\n')
		end
		addLaTeX('\\newcommand*{\\setstartingpage}{}\n')
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
		addLaTeX('\\newcommand*{\\print'..key..'line}{'..command..'}\n'
			)
	end

	-- DOI
	--	`\printdoiurl` is used by `\printcitation`
	local doi, doiurl = '', ''
	if meta.doi then
		doi = stringify(meta.doi)
		addLaTeX('\\newcommand*{\\printdoiurl}{'
				..'https://doi.org/'..doi
			..'}\n')
		addLaTeX('\\newcommand*{\\printdoi}{'
				..'\\href{\\printdoiurl}{'..doi..'}'
			..'}\n'
			)

	else
		addLaTeX('\\newcommand*{\\printdoi}{\\relax}')
		addLaTeX('\\newcommand*{\\printdoiurl}{\\relax}')
	end

	-- Dublin Core
	-- needs year and authors_str_html
	local dc = meta.dc or {}
	local copyright = (year and year..' ' or '')..authors_str_html
	dc.type = 'Text.Serial.Journal'
	dc.articleType = 'Articles'
	dc.source = 'Dialectica'
	dc['source-URI'] = 'https://dialectica.philosophie.ch/'
	dc.rights = {
		'Copyright (c) '..copyright,
		'https://creativecommons.org/licenses/by/4.0',
	}
	meta.dc = dc

	-- LISTS: editorial board and committees, indexing services

	local linelists = {'editorialboard','journaleditors','revieweditors'}
	local commalists = {'editorialcommittee','consultingboard',
					'indexingservices', 'sponsors'}

	for _,key in ipairs(linelists) do
		if meta[key] then
		addLaTeX(
			'\\newcommand{\\' .. key .. '}{%\n'
			.. latexListify(meta[key], ' \\\\\n')
			.. '%\n}\n'
			)
		end
	end

	for _,key in ipairs(commalists) do
		if meta[key] then
			addLaTeX(
				'\\newcommand{\\' .. key .. '}{%\n'
				.. latexListify(meta[key], ', ')
				.. '%\n}\n'
				)
		end
	end

	if not meta['header-includes'] 
		or type(meta['header-includes']) ~= 'List' then
			meta['header-includes'] = pandoc.MetaList({meta['header-includes']})
	end

	-- insert LaTeX commands if output is LaTeX
	if FORMAT:match('latex') then
		meta['header-includes']:insert(1, pandoc.MetaBlocks(
			pandoc.RawBlock('latex', latexCommands)
		))
	end

	return meta

end

return {
	{
		Meta = metaformat
	}
}