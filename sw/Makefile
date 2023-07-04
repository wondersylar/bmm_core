ISA_SRC_DIR := ./riscv-tests/isa
BMARKS_SRC_DIR := ./riscv-tests/benchmarks

rv32ui:
	mkdir -p build/isa
	$(MAKE) -C $(ISA_SRC_DIR) rv32ui 
	mv $(ISA_SRC_DIR)/rv32ui-* build/isa

rv32um:
	mkdir -p build/isa
	$(MAKE) -C $(ISA_SRC_DIR) rv32um 
	mv $(ISA_SRC_DIR)/rv32um-* build/isa

benchmarks:
	mkdir -p build/benchmarks
	$(MAKE) -C $(BMARKS_SRC_DIR) all 
	mv $(BMARKS_SRC_DIR)/*.riscv* build/benchmarks
	

isa:rv32um rv32ui

clean: clean_benchmarks clean_isa

clean_benchmarks:
	[ ! -d build/benchmarks ]     || $(MAKE) -C $(BMARKS_SRC_DIR)  clean ; rm -rf ./build/benchmarks
	
clean_isa:
	[ ! -d build/isa ]    || $(MAKE) -C $(ISA_SRC_DIR)     clean ; rm -rf ./build/isa





