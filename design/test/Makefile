
TEST := isa
#TEST := benchmarks 
TESTCASE := ../../sw/build/$(TEST)/rv32um-p-rem.hex


compile:clean
	#$(MAKE) -C ../../sw $(TEST)
	vcs  -full64 -sverilog +v2k\
		+libext+.v+.V+.sv+.svh \
		-kdb -lca\
		-debug_all  +nbaopt +nospecify +notimingcheck  \
		+acc \
		+vpi \
		-assert svaext \
		+vcs+lic+wait \
		-Mdir=csrc \
		+lint=TFIPC-L \
		-timescale=1ns/1ps \
		-P /opt/tools/synopsys/verdi_2017.12/share/PLI/VCS/linux64/novas_new_dumper.tab /opt/tools/synopsys/verdi_2017.12/share/PLI/VCS/linux64/pli.a \
		+vcsd \
		-l compile.log \
		-o simv \
		-j128 \
		-top tb_bmm\
		-f ../bmm.f 


vcs:compile
	./simv +FSDB +fsdb+struct +testcase=$(TESTCASE) +$(TEST) -l sim.log 

sim:
	./simv +FSDB +fsdb+struct +testcase=$(TESTCASE) +$(TEST) -l sim.log 


debug:clean
	$(MAKE) -C ../../sw $(TEST)
	vcs  -full64 -sverilog +v2k\
		+libext+.v+.V+.sv+.svh \
		-kdb -lca\
		-debug_all  +nbaopt +nospecify +notimingcheck  \
		+acc \
		+vpi \
		-assert svaext \
		+vcs+lic+wait \
		-Mdir=csrc \
		+lint=TFIPC-L \
		-top tb_bmm \
		-timescale=1ns/1ps \
		-P /opt/tools/synopsys/verdi_2017.12/share/PLI/VCS/linux64/novas_new_dumper.tab /opt/tools/synopsys/verdi_2017.12/share/PLI/VCS/linux64/pli.a \
		+vcsd \
		-l compile.log \
		-o simv \
		-f ../bmm.f \
		./jtag/SimJTAG.v  \
		./jtag/SimJTAG.cc \
		./jtag/remote_bitbang.cc \
		+define+DBG_ENABLE \
		-j128
	./simv +FSDB +fsdb+struct +testcase=$(TESTCASE) +$(TEST) -l sim.log 



clean:
	rm -rf compile.log csrc simv simv.daidir ucli.key vc_hdrs.h novas_dump.log *.fsdb novas* verdiLog signal.rc sim.log *_1.log *_0.log 
	#$(MAKE) -C ../../sw clean_$(TEST)

verdi:
	verdi -dbdir simv.daidir -ssf tb_bmm.fsdb 
