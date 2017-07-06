# See LICENSE for license details.

# check RISCV environment variable
ifndef VCS_HOME
    $(error VCS is not ready yet)
endif

#--------------------------------------------------------------------
# global define
#--------------------------------------------------------------------

default: sim

base_dir = $(abspath ..)
sim_dir = .
output_dir = $(sim_dir)/output
mem_gen = $(abspath ./vlsi_mem_gen)
generated_dir = $(abspath ./generated-src)

BACKEND ?= lowrisc_chip.LowRISCBackend

SBT := java -Xmx2048M -Xss8M -XX:MaxPermSize=256M -jar sbt-launch.jar

.PHONY: default

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

chisel_src_path = src/main/scala
default_submodules = . uncore
chisel_srcs := $(addprefix $(base_dir)/,$(addsuffix /$(chisel_src_path)/*.scala,$(default_submodules)))

verilog_srcs = \
	$(base_dir)/socip/nasti/channel.sv \

verilog_headers = \

test_verilog_srcs = \
	$(base_dir)/uncore/src/test/verilog/tagcache/tagcache_tb.sv \
	$(base_dir)/src/test/verilog/nasti_ram_behav.sv \

test_cxx_srcs = \
	$(base_dir)/src/test/cxx/common/loadelf.cpp \
	$(base_dir)/src/test/cxx/common/dpi_ram_behav.cpp \

test_cxx_headers = \
	$(base_dir)/src/test/cxx/common/loadelf.hpp \
	$(base_dir)/src/test/cxx/common/dpi_ram_behav.h \

dpi_libs = \
	$(sim_dir)/libdpi.so \

#--------------------------------------------------------------------
# Build DPI
#--------------------------------------------------------------------

$(sim_dir)/libdpi.so : $(test_verilog_srcs) $(test_cxx_srcs) $(test_cxx_headers)
	g++ -Wa,-W -fPIC -m64 -O1 -std=c++11 -shared \
	-I$(base_dir)/csrc/common \
	-I$(VCS_HOME)/include \
	$(test_cxx_srcs) -o $@

#	-DVERBOSE_MEMORY \

junk += $(sim_dir)/libdpi.so

#--------------------------------------------------------------------
# Build Verilog
#--------------------------------------------------------------------

# is there a better way to do this boilerplates?


$(generated_dir)/TagCacheTop.BigTCConfig.sv: $(chisel_srcs)
	cd $(base_dir) && mkdir -p $(generated_dir) && \
	$(SBT) "run uncore TagCacheTop lowrisc_chip BigTCConfig --W0W --minimumCompatibility 3.0.0 --backend $(BACKEND) --configName BigTCConfig --compileInitializationUnoptimized  --targetDir $(generated_dir) --configDump --noInlineMem"
	$(mem_gen) $(generated_dir)/TagCacheTop.BigTCConfig.conf >> $(generated_dir)/TagCacheTop.BigTCConfig.sv
	echo "\`ifndef CONST_VH" > $(generated_dir)/TagCacheTop.BigTCConfig.consts.vh
	echo "\`define CONST_VH" >> $(generated_dir)/TagCacheTop.BigTCConfig.consts.vh
	sed -r 's/\(([A-Za-z0-9_]+),([0-9]+)\)/  `define \1 '\''d\2/' $(generated_dir)/TagCacheTop.BigTCConfig.prm >> $(generated_dir)/TagCacheTop.BigTCConfig.consts.vh
	echo "\`endif // CONST_VH" >> $(generated_dir)/TagCacheTop.BigTCConfig.consts.vh

$(generated_dir)/TagCacheTop.BigParallelTCConfig.sv: $(chisel_srcs)
	cd $(base_dir) && mkdir -p $(generated_dir) && \
	$(SBT) "run uncore TagCacheTop lowrisc_chip BigParallelTCConfig --W0W --minimumCompatibility 3.0.0 --backend $(BACKEND) --configName BigParallelTCConfig --compileInitializationUnoptimized  --targetDir $(generated_dir) --configDump --noInlineMem"
	$(mem_gen) $(generated_dir)/TagCacheTop.BigParallelTCConfig.conf >> $(generated_dir)/TagCacheTop.BigParallelTCConfig.sv
	echo "\`ifndef CONST_VH" > $(generated_dir)/TagCacheTop.BigParallelTCConfig.consts.vh
	echo "\`define CONST_VH" >> $(generated_dir)/TagCacheTop.BigParallelTCConfig.consts.vh
	sed -r 's/\(([A-Za-z0-9_]+),([0-9]+)\)/  `define \1 '\''d\2/' $(generated_dir)/TagCacheTop.BigParallelTCConfig.prm >> $(generated_dir)/TagCacheTop.BigParallelTCConfig.consts.vh
	echo "\`endif // CONST_VH" >> $(generated_dir)/TagCacheTop.BigParallelTCConfig.consts.vh

$(generated_dir)/TagCacheTop.SmallTCConfig.sv: $(chisel_srcs)
	cd $(base_dir) && mkdir -p $(generated_dir) && \
	$(SBT) "run uncore TagCacheTop lowrisc_chip SmallTCConfig --W0W --minimumCompatibility 3.0.0 --backend $(BACKEND) --configName SmallTCConfig --compileInitializationUnoptimized  --targetDir $(generated_dir) --configDump --noInlineMem"
	$(mem_gen) $(generated_dir)/TagCacheTop.SmallTCConfig.conf >> $(generated_dir)/TagCacheTop.SmallTCConfig.sv
	echo "\`ifndef CONST_VH" > $(generated_dir)/TagCacheTop.SmallTCConfig.consts.vh
	echo "\`define CONST_VH" >> $(generated_dir)/TagCacheTop.SmallTCConfig.consts.vh
	sed -r 's/\(([A-Za-z0-9_]+),([0-9]+)\)/  `define \1 '\''d\2/' $(generated_dir)/TagCacheTop.SmallTCConfig.prm >> $(generated_dir)/TagCacheTop.SmallTCConfig.consts.vh
	echo "\`endif // CONST_VH" >> $(generated_dir)/TagCacheTop.SmallTCConfig.consts.vh

$(generated_dir)/TagCacheTop.SmallParallelTCConfig.sv: $(chisel_srcs)
	cd $(base_dir) && mkdir -p $(generated_dir) && \
	$(SBT) "run uncore TagCacheTop lowrisc_chip SmallParallelTCConfig --W0W --minimumCompatibility 3.0.0 --backend $(BACKEND) --configName SmallParallelTCConfig --compileInitializationUnoptimized  --targetDir $(generated_dir) --configDump --noInlineMem"
	$(mem_gen) $(generated_dir)/TagCacheTop.SmallParallelTCConfig.conf >> $(generated_dir)/TagCacheTop.SmallParallelTCConfig.sv
	echo "\`ifndef CONST_VH" > $(generated_dir)/TagCacheTop.SmallParallelTCConfig.consts.vh
	echo "\`define CONST_VH" >> $(generated_dir)/TagCacheTop.SmallParallelTCConfig.consts.vh
	sed -r 's/\(([A-Za-z0-9_]+),([0-9]+)\)/  `define \1 '\''d\2/' $(generated_dir)/TagCacheTop.SmallParallelTCConfig.prm >> $(generated_dir)/TagCacheTop.SmallParallelTCConfig.consts.vh
	echo "\`endif // CONST_VH" >> $(generated_dir)/TagCacheTop.SmallParallelTCConfig.consts.vh

$(generated_dir)/TagCacheTop.SmallSmallTCConfig.sv: $(chisel_srcs)
	cd $(base_dir) && mkdir -p $(generated_dir) && \
	$(SBT) "run uncore TagCacheTop lowrisc_chip SmallSmallTCConfig --W0W --minimumCompatibility 3.0.0 --backend $(BACKEND) --configName SmallSmallTCConfig --compileInitializationUnoptimized  --targetDir $(generated_dir) --configDump --noInlineMem"
	$(mem_gen) $(generated_dir)/TagCacheTop.SmallSmallTCConfig.conf >> $(generated_dir)/TagCacheTop.SmallSmallTCConfig.sv
	echo "\`ifndef CONST_VH" > $(generated_dir)/TagCacheTop.SmallSmallTCConfig.consts.vh
	echo "\`define CONST_VH" >> $(generated_dir)/TagCacheTop.SmallSmallTCConfig.consts.vh
	sed -r 's/\(([A-Za-z0-9_]+),([0-9]+)\)/  `define \1 '\''d\2/' $(generated_dir)/TagCacheTop.SmallSmallTCConfig.prm >> $(generated_dir)/TagCacheTop.SmallSmallTCConfig.consts.vh
	echo "\`endif // CONST_VH" >> $(generated_dir)/TagCacheTop.SmallSmallTCConfig.consts.vh


junk += $(generated_dir)

#--------------------------------------------------------------------
# Build rules (VCS)
#--------------------------------------------------------------------
VCS = vcs
VCS_FLAG = \
	-sverilog -ntb_opts -full64 \
	-timescale=1ns/10ps \
	-debug \
	+incdir+$(generated_dir) \
	+incdir+$(base_dir)/src/main/verilog \
	+incdir+$(base_dir)/socip/nasti \

#--------------------------------------------------------------------
# Build the simulator (VCS)
#--------------------------------------------------------------------
BigTagCache-sim: $(generated_dir)/TagCacheTop.BigTCConfig.sv $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(dpi_libs)
	cp $(generated_dir)/TagCacheTop.BigTCConfig.consts.vh $(generated_dir)/tagcache.consts.vh
	$(VCS) $(VCS_FLAG) $(generated_dir)/TagCacheTop.BigTCConfig.sv $(verilog_srcs) $(test_verilog_srcs) \
	-top tb \
	-o $@ $(dpi_libs)

BigParallelTagCache-sim: $(generated_dir)/TagCacheTop.BigParallelTCConfig.sv $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(dpi_libs)
	cp $(generated_dir)/TagCacheTop.BigParallelTCConfig.consts.vh $(generated_dir)/tagcache.consts.vh
	$(VCS) $(VCS_FLAG) $(generated_dir)/TagCacheTop.BigParallelTCConfig.sv $(verilog_srcs) $(test_verilog_srcs) \
	-top tb \
	-o $@ $(dpi_libs)

SmallTagCache-sim: $(generated_dir)/TagCacheTop.SmallTCConfig.sv $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(dpi_libs)
	cp $(generated_dir)/TagCacheTop.SmallTCConfig.consts.vh $(generated_dir)/tagcache.consts.vh
	$(VCS) $(VCS_FLAG) $(generated_dir)/TagCacheTop.SmallTCConfig.sv $(verilog_srcs) $(test_verilog_srcs) \
	-top tb \
	-o $@ $(dpi_libs)

SmallParallelTagCache-sim: $(generated_dir)/TagCacheTop.SmallParallelTCConfig.sv $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(dpi_libs)
	cp $(generated_dir)/TagCacheTop.SmallParallelTCConfig.consts.vh $(generated_dir)/tagcache.consts.vh
	$(VCS) $(VCS_FLAG) $(generated_dir)/TagCacheTop.SmallParallelTCConfig.sv $(verilog_srcs) $(test_verilog_srcs) \
	-top tb \
	-o $@ $(dpi_libs)

SmallSmallTagCache-sim: $(generated_dir)/TagCacheTop.SmallSmallTCConfig.sv $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(dpi_libs)
	cp $(generated_dir)/TagCacheTop.SmallSmallTCConfig.consts.vh $(generated_dir)/tagcache.consts.vh
	$(VCS) $(VCS_FLAG) $(generated_dir)/TagCacheTop.SmallSmallTCConfig.sv $(verilog_srcs) $(test_verilog_srcs) \
	-top tb \
	-o $@ $(dpi_libs)

junk += *-sim* csrc DVEfiles simv.daidir

#--------------------------------------------------------------------
# Run (VCS)
#--------------------------------------------------------------------

unitest: $(output_dir)/BigTagCache.sim.log $(output_dir)/BigParallelTagCache.sim.log $(output_dir)/SmallTagCache.sim.log $(output_dir)/SmallParallelTagCache.sim.log $(output_dir)/SmallSmallTagCache.sim.log

$(output_dir)/%.sim.log: %-sim
	mkdir -p $(output_dir)
	$< +max-xact=1000000 -l $@ > /dev/null
	grep "finish" $@ && ! grep "Fatal" $@

junk += $(output_dir)
.PHONY: unitest

#--------------------------------------------------------------------
# clean up
#--------------------------------------------------------------------

clean:
	rm -rf $(junk) .nodeIdDynamicRanges opendatabase.log ucli.key \
	vc_hdrs.h vcs.man

.PHONY: clean
