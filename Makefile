test:
	@echo "Run tests"
	nvim --headless --noplugin -u tests/minimal_init.vim -c "PlenaryBustedDirectory tests/ { minimal_init = './tests/minimal_init.vim' }"

.PHONY: test
