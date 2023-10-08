--[[-- # Scholarly-format - a Pandoc Lua filter for creating academic
	journal templates

To be used with (and after) the scholarly-metadata filter. 

This filter populates a document's metadata with pre-formatted 
fields that can be used by custom Pandoc templates to typeset
journal articles. 

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@copyright 2021 Julien Dutant
@license MIT - see LICENSE file for details.
@release 0.1

]]

local List = pandoc.List
local stringify = pandoc.utils.stringify

local function process(meta)

	-- localize the last 'and' in lists
	meta.localize = {
		lastand = pandoc.MetaInlines(pandoc.Str('&')),
	}

	-- add institutename list to the metadata `author` field
	-- assumes that the author field is a list
	meta.author = List:new(meta.author):map(
		function (author)
			author.institutename = List:new(author.institute):map(
				function (institute_index)
					return meta.institute[tonumber(institute_index)].name
				end
			)
			return author
		end
		)
	
	-- checks if email of correspondence author is empty
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


	return meta

end

--- Main code
-- process the meta element
function Meta(meta)
 	return  process(meta)
end
