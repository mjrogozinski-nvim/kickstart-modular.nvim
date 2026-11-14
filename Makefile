NVIM ?= nvim

.PHONY: tests

tests:
	$(NVIM) --headless -i NONE -u tests/minimal_init.lua \
		"+luafile tests/validate-gtest-run-mapping.lua"

.PHONY: tests-cmake-run
tests-cmake-run:
	$(NVIM) --headless -i NONE -u tests/minimal_init.lua \
		"+luafile tests/validate-cmake-run.lua"
