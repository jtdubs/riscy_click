.PHONY: validate

CONFIG = config.ini
ENV    = riscv-arch-test/riscv-test-suite/env/
SUITE  = riscv-arch-test/riscv-test-suite/rv32i_m/

validate:
	riscof validateyaml --config=$(CONFIG)

testlist:
	riscof testlist --config=$(CONFIG) --env $(ENV) --suite $(SUITE)

run:
	riscof run --config=$(CONFIG) --env $(ENV) --suite $(SUITE)
