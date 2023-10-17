#!/usr/bin/env bash

# Script to create dialectica's css
# This simply runs the less compiler with the clean-css plugin. 
#
# Requirements
#
# - lessc <https://lesscss.org>
# - clean-css plugin for less-css <https://www.npmjs.com/package/less-plugin-clean-css>
# 
# Install both with node package manager:		
#
# 	npm install lessc less-plu
# 	Install (globally) with node package manager:
#		
# 		npm install -g lessc less-plugin-clean-css
#		
lessc dialectica.less --clean-css > dialectica.css
