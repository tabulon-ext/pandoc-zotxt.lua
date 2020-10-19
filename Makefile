# Interpret Makefile according to POSIX standard.
.POSIX:

# DIRECTORIES
# ===========

BASE_DIR	:= test
DATA_DIR	:= $(BASE_DIR)/data
NORM_DIR	:= $(BASE_DIR)/norms
SCPT_DIR	:= $(BASE_DIR)/scripts
TMP_DIR		:= $(BASE_DIR)/tmp


# PROGRAMMES
# ==========

SHELL		?= sh
RM		?= rm -f
PANDOC		?= pandoc

# TARGETS
# =======

BEHAVIOUR_TESTS	:= test-easy-citekey test-better-bibtex test-zotero-id \
		   test-bibliography




# TESTS
# =====

test: unit-tests behaviour-tests

behaviour-tests: $(BEHAVIOUR_TESTS)

install-luaunit:
	[ -e "share/lua/5.3/luaunit.lua" ] || \
		luarocks install --tree=. luaunit

prepare-tmpdir:
	mkdir -p "$(TMP_DIR)"
	$(RM) "$(TMP_DIR)"/*
	cd -P "$(TMP_DIR)" || exit

unit-tests: install-luaunit prepare-tmpdir
	$(PANDOC) --lua-filter "$(SCPT_DIR)/unit-tests.lua" \
		-f markdown -t plain $(CANNED_RESPONSES) -o /dev/null </dev/null

$(BEHAVIOUR_TESTS): prepare-tmpdir
	if $(PANDOC) --lua-filter "$(SCPT_DIR)/pre-v2_11.lua" \
		-f markdown -t plain /dev/null >/dev/null 2>&1; \
	then \
		$(PANDOC) --lua-filter "$(SCPT_DIR)/debug-wrapper.lua" \
			--filter pandoc-citeproc \
			$(CANNED_RESPONSES) -o "$(TMP_DIR)/$@.html" "$(DATA_DIR)/$@.md"; \
		cmp "$(TMP_DIR)/$@.html" "$(NORM_DIR)/pre-v2_11/$@.html"; \
	else \
		$(PANDOC) --lua-filter "$(SCPT_DIR)/debug-wrapper.lua" \
			--citeproc \
			$(CANNED_RESPONSES) -o "$(TMP_DIR)/$@.html" "$(DATA_DIR)/$@.md"; \
		cmp "$(TMP_DIR)/$@.html" "$(NORM_DIR)/$@.html"; \
	fi

manual:
	$(PANDOC) -o man/pandoc-zotxt.lua.1 -f markdown-smart -t man -s \
		-M title=pandoc-zotxt.lua  \
		-M date="$$(date '+%B %d, %Y')" \
		-M section=1 \
		man/pandoc-zotxt.lua.md

prologue:
	@$(PANDOC) -f markdown-smart -t plain man/pandoc-zotxt.lua.md | \
		sed 's/^\(.\)/-- \1/; s/^$$/--/;'

.PHONY: install-luaunit prepare-tmpdir test unit-tests behaviour-tests  \
	$(BEHAVIOUR_TESTS) unit-tests manual prologue
