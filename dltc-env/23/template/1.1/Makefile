# Dialectica template update Makefile
# 	Updates the template files with latest versions of resources
#	Only meant to be used on Julien's computer
VERSION = $(notdir $(CURDIR))
GITHUB = /Users/julien/GitHub/
DIALCODE = /Users/julien/Dropbox/dialectica-code/

NAMES := collection/collection.lua \
	columns/columns.lua \
	imagify/_extensions/imagify/imagify.lua \
	first-line-indent/first-line-indent.lua \
	dialectica-filters/bib-place/bib-place.lua \
	dialectica-filters/secnumdepth/secnumdepth.lua \
	dialectica-filters/functions/image-attributes/image-attributes.lua \
	dialectica-filters/labelled-lists/labelled-lists.lua \
	dialectica-filters/not-in-format/not-in-format.lua \
	recursive-citeproc/recursive-citeproc.lua \
	dialectica-filters/sections-to-meta/sections-to-meta.lua \
	dialectica-filters/functions/statement-isolate/statement-isolate.lua \
	statement/_extensions/statement/statement.lua \
	lua-filters/scholarly-metadata/scholarly-metadata.lua

FILES = $(addprefix $(GITHUB), $(NAMES))	

.PHONY: all update backup backup_confirm
all:

ifneq ($(wildcard $(GITHUB).*),)
update: 
	@echo "Update filters"
	cp $(FILES) ./filters
	@echo "Update pandokoma LaTeX template"
	cp $(GITHUB)pandokoma/pandokoma-bare.latex ./templates/dialectica.latex
	@echo "Update complete"

backup: backup_confirm
	@echo "Backup template"
	rm -rf $(DIALCODE)templates/$(VERSION)
	cp -R $(CURDIR) $(DIALCODE)templates/$(VERSION)
	@echo "Backup complete"

backup_confirm:
	@echo -n "Backup to dialectica-code/templates/$(VERSION)? [y/N] " \
		&& read ans && [ $${ans:-N} = y ]

else
update: errormsg

backup: errormsg

errormsg:
	@echo "Error: this update script can only be run on Julien's computer."
endif
