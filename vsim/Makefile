# See LICENSE.Cambridge for license details.

# check Verilator environment variable
ifndef VERILATOR_ROOT
$(error Please set environment for the Verilator simulator)
endif

#--------------------------------------------------------------------
# global define
#--------------------------------------------------------------------

default: sim

base_dir = $(abspath ../rocket-chip)
sim_dir = .
output_dir = $(sim_dir)/output
mem_gen = $(base_dir)/scripts/vlsi_mem_gen
generated_dir = $(abspath ./generated-src)

glip_dir = $(abspath ..)/opensocdebug/glip/src
osd_dir = $(abspath ..)/opensocdebug/hardware

BACKEND ?= v
CONFIG ?= DefaultFPGAConfig

include $(abspath ..)/Makefrag

.PHONY: default

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

bootrom_image = $(base_dir)/bootrom/bootrom.img

lowrisc_srcs = \
	$(generated_dir)/$(MODEL).$(CONFIG).sv \
	$(generated_dir)/$(MODEL).$(CONFIG).behav_srams.sv \

lowrisc_headers = \
	$(generated_dir)/consts.vh \
	$(generated_dir)/consts.hpp \

verilog_srcs = \
	$(osd_dir)/interfaces/common/dii_channel.sv \
	$(base_dir)/src/main/verilog/chip_top.sv \
	$(base_dir)/socip/nasti/channel.sv \
	$(base_dir)/socip/nasti/lite_nasti_reader.sv \
	$(base_dir)/socip/nasti/lite_nasti_writer.sv \
	$(base_dir)/socip/nasti/nasti_bram_ctrl.sv \
	$(base_dir)/socip/nasti/nasti_buf.sv \
	$(base_dir)/socip/nasti/nasti_combiner.sv \
	$(base_dir)/socip/nasti/nasti_crossbar.sv \
	$(base_dir)/socip/nasti/nasti_demux.sv \
	$(base_dir)/socip/nasti/nasti_lite_bridge.sv \
	$(base_dir)/socip/nasti/nasti_lite_reader.sv \
	$(base_dir)/socip/nasti/nasti_lite_writer.sv \
	$(base_dir)/socip/nasti/nasti_mux.sv \
	$(base_dir)/socip/nasti/nasti_narrower_reader.sv \
	$(base_dir)/socip/nasti/nasti_narrower.sv \
	$(base_dir)/socip/nasti/nasti_narrower_writer.sv \
	$(base_dir)/socip/nasti/nasti_slicer.sv \
	$(base_dir)/socip/util/arbiter.sv \
	$(base_dir)/vsrc/AsyncResetReg.v \
	$(base_dir)/vsrc/plusarg_reader.v \
	$(base_dir)/vsrc/vsim_bscan_dummy.v \

verilog_headers = \
	$(base_dir)/src/main/verilog/config.vh \
	$(base_dir)/socip/nasti/nasti_request.vh \

test_verilog_srcs = \
	$(base_dir)/src/test/verilog/host_behav.sv \
	$(base_dir)/src/test/verilog/nasti_ram_behav.sv \

test_cxx_srcs = \
	$(base_dir)/src/test/cxx/common/globals.cpp \
	$(base_dir)/src/test/cxx/common/loadelf.cpp \
	$(base_dir)/src/test/cxx/common/dpi_host_behav.cpp \
	$(base_dir)/src/test/cxx/common/dpi_ram_behav.cpp \
	$(base_dir)/src/test/cxx/veri/veri_top.cc \

test_cxx_headers = \
	$(base_dir)/src/test/cxx/common/globals.h \
	$(base_dir)/src/test/cxx/common/loadelf.hpp \
	$(base_dir)/src/test/cxx/common/dpi_ram_behav.h \
	$(base_dir)/src/test/cxx/common/dpi_host_behav.h \

#--------------------------------------------------------------------
# Build Verilog
#--------------------------------------------------------------------

verilog: $(lowrisc_srcs) $(lowrisc_headers)

include $(abspath ..)/Makefrag-build

.PHONY: verilog
junk += $(generated_dir)

#--------------------------------------------------------------------
# Build rules (verilator)
#--------------------------------------------------------------------
veri = verilator
tb_top = chip_top

veri_flags = \
	+incdir+$(generated_dir) \
	+incdir+$(base_dir)/src/main/verilog \
	+incdir+$(base_dir)/socip/nasti \
	+incdir+$(base_dir)/minion_subsystem/verilog \
    +incdir+$(base_dir)/minion_subsystem/pulpino/rtl/includes \
    +incdir+$(base_dir)/minion_subsystem/pulpino/ips/riscv/include \
	+define+PRINTF_COND=1 \
	+define+STOP_COND=1 \
	--top-module $(tb_top) \
	--unroll-count 256 \
	--error-limit 500 \
    --output-split 20000 \
	--output-split-cfuncs 20000 \
	-Wno-lint -Wno-style -Wno-STMTDLY -Wno-ASSIGNIN\
	--x-assign unique \
	-CFLAGS "-std=c++11" \
	-CFLAGS "-I$(base_dir)/src/test/cxx/common -I$(base_dir)/src/test/cxx/veri -I$(glip_dir)/backend_tcp/logic/dpi" \
	-LDFLAGS "-pthread" \
	--exe \
	--assert \

#	-DRANDOMIZE_GARBAGE_ASSIGN \
#	-DRANDOMIZE_INVALID_ASSIGN \
#	-DRANDOMIZE_REG_INIT \
#	-DRANDOMIZE_MEM_INIT \

# remove optimization if compilation takes too long or run out of memory
veri_opt_flags = --Mdir $(sim_dir)/verilator.opt -O3 -CFLAGS "-O3"
veri_norm_flags = --Mdir $(sim_dir)/verilator.norm --trace -O1 -CFLAGS "-O1"
veri_dbg_flags = --Mdir $(sim_dir)/verilator.debug --trace -O1 -CFLAGS "-O1 -DDELAY_EXIT -DTRACE_VCD"

#--------------------------------------------------------------------
# Build the simulator (verilator)
#--------------------------------------------------------------------
verilator: verilator.norm.log
verilator.norm.log: $(lowrisc_srcs) $(lowrisc_headers) $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(test_cxx_srcs) $(test_cxx_headers)
	rm -fr $(sim_dir)/verilator.norm
	$(veri) --cc $(lowrisc_srcs) $(verilog_srcs) $(test_verilog_srcs) $(test_cxx_srcs) $(veri_flags) $(veri_norm_flags) -o ../$(CONFIG)-sim 2>&1 | tee $@

sim: $(CONFIG)-sim
$(CONFIG)-sim: verilator.norm.log
	VM_PARALLEL_BUILDS=1 $(MAKE) -C verilator.norm -f V$(tb_top).mk

verilator.debug.log: $(lowrisc_srcs) $(lowrisc_headers) $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(test_cxx_srcs) $(test_cxx_headers)
	rm -fr $(sim_dir)/verilator.debug
	$(veri) --cc $(lowrisc_srcs) $(verilog_srcs) $(test_verilog_srcs) $(test_cxx_srcs) $(veri_flags) $(veri_dbg_flags) -o ../$(CONFIG)-sim-debug | tee $@

sim-debug: $(CONFIG)-sim-debug
$(CONFIG)-sim-debug: verilator.debug.log
	VM_PARALLEL_BUILDS=1 $(MAKE) -C verilator.debug -f V$(tb_top).mk

verilator.opt.log: verilator.opt.log
verilator.opt.log: $(lowrisc_srcs) $(lowrisc_headers) $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(test_cxx_srcs) $(test_cxx_headers)
	rm -fr $(sim_dir)/verilator.opt
	$(veri) --cc $(lowrisc_srcs) $(verilog_srcs) $(test_verilog_srcs) $(test_cxx_srcs) $(veri_flags) $(veri_norm_flags) -o ../$(CONFIG)-sim 2>&1 | tee $@

sim-opt: $(CONFIG)-sim-opt
$(CONFIG)-sim-opt: verilator.opt.log
	VM_PARALLEL_BUILDS=1 $(MAKE) -C verilator.opt -f V$(tb_top).mk

.PHONY: verilator sim sim-debug sim-opt

junk += $(generated_dir) $(CONFIG)-sim verilator.norm verilator.norm.log $(CONFIG)-sim-debug verilator.debug verilator.debug.log $(CONFIG)-sim-opt verilator.opt verilator.opt.log

#--------------------------------------------------------------------
# Test cases
#--------------------------------------------------------------------
rv32ui = simple add addi and andi auipc beq bge bgeu blt bltu bne fence_i \
         jal jalr lb lbu lh lhu lui lw or ori sb sh sw sll slli \
         slt slti sra srai srl srli sub xor xori \

rv32uc = rvc

rv32um = mul mulh mulhsu mulhu div divu rem remu \

rv32ua = amoadd_w amoand_w amoor_w amoxor_w amoswap_w amomax_w amomaxu_w amomin_w amominu_w lrsc \

rv32si = csr ma_fetch scall sbreak wfi dirty \

rv32mi = csr mcsr illegal ma_addr ma_fetch sbreak scall \

rv64ui = $(rv32ui) addw addiw ld lwu sd slliw sllw sltiu sltu sraiw sraw srliw srlw subw \

rv64uc = $(rv32uc)

rv64um = $(rv32um) divuw divw mulw remuw remw \

rv64ua = $(rv32ua) amoadd_d amoand_d amoor_d amoxor_d amoswap_d amomax_d amomaxu_d amomin_d amominu_d \

rv64uf = ldst move fcmp fcvt fcvt_w fclass fadd fdiv fmin fmadd \

rv64ud = $(rv64uf) structural \

rv64si = $(rv32si)

rv64mi = $(rv32mi) breakpoint

bmarks = median multiply qsort towers vvadd mm dhrystone spmv mt-vvadd mt-matmul

rv64tag_ui = tagrw alu load store storekeep jmp

rv64tag_mi = alucheck loadcheck storecheck pctag jmpcheck fetchcheck

rv64tag_si = alucheck-s loadcheck-s storecheck-s pctag-s jmpcheck-s fetchcheck-s

tagcaches = loadstore

#--------------------------------------------------------------------
asm_p_tests  += $(addprefix rv64ui-p-, $(rv64ui))
asm_p_tests  += $(addprefix rv64uc-p-, $(rv64uc))
asm_p_tests  += $(addprefix rv64um-p-, $(rv64um))
asm_p_tests  += $(addprefix rv64ua-p-, $(rv64ua))
asm_p_tests  += $(addprefix rv64ud-p-, $(rv64ud))
asm_p_tests  += $(addprefix rv64si-p-, $(rv64si))
asm_p_tests  += $(addprefix rv64mi-p-, $(rv64mi))

asm_v_tests  += $(addprefix rv64ui-v-, $(rv64ui))
asm_v_tests  += $(addprefix rv64uc-v-, $(rv64uc))
asm_v_tests  += $(addprefix rv64um-v-, $(rv64um))
asm_v_tests  += $(addprefix rv64ua-v-, $(rv64ua))
asm_v_tests  += $(addprefix rv64ud-v-, $(rv64ud))

bmarks_tests += $(bmarks)

tag_tests    += $(addprefix rv64tag-p-, $(rv64tag_ui) $(rv64tag_mi) $(rv64tag_si))
tag_tests    += $(addprefix rv64tag-v-, $(rv64tag_ui))

tagcache_tests += $(tagcaches)

#--------------------------------------------------------------------
riscv_test_asm_dir      = $(sim_dir)/riscv-tests/isa
riscv_test_bmarks_dir   = $(sim_dir)/riscv-tests/benchmarks
riscv_test_tag_dir      = $(sim_dir)/riscv-tests/tag
riscv_test_tagcache_dir = $(sim_dir)/riscv-tests/tagcache

$(addprefix $(output_dir)/, $(addsuffix .riscv, $(asm_p_tests) $(asm_v_tests))):
	mkdir -p $(output_dir)
	$(MAKE) -C $(riscv_test_asm_dir) $(basename $(notdir $@))
	ln -fs ../$(riscv_test_asm_dir)/$(basename $(notdir $@)) $@

$(addprefix $(output_dir)/, $(addsuffix .riscv, $(bmarks_tests))):
	mkdir -p $(output_dir)
	$(MAKE) -C $(riscv_test_bmarks_dir) $(basename $(notdir $@))
	ln -fs ../$(riscv_test_bmarks_dir)/$(basename $(notdir $@)) $@

$(addprefix $(output_dir)/, $(addsuffix .riscv, $(tag_tests))):
	mkdir -p $(output_dir)
	$(MAKE) -C $(riscv_test_tag_dir) $(basename $(notdir $@))
	ln -fs ../$(riscv_test_tag_dir)/$(basename $(notdir $@)) $@

$(addprefix $(output_dir)/, $(addsuffix .riscv, $(tagcache_tests))):
	mkdir -p $(output_dir)
	$(MAKE) -C $(riscv_test_tagcache_dir) $(notdir $@)
	ln -fs ../$(riscv_test_tagcache_dir)/$(notdir $@) $@


#--------------------------------------------------------------------
# Run (verilator)
#--------------------------------------------------------------------
asm_tests_out    = $(foreach test, $(asm_p_tests) $(asm_v_tests), $(output_dir)/$(test).verilator.out)
bmarks_out       = $(foreach test, $(bmarks_tests),               $(output_dir)/$(test).verilator.out)
asm_tag_out      = $(foreach test, $(tag_tests),                  $(output_dir)/$(test).verilator.out)
asm_tagcache_out = $(foreach test, $(tagcache_tests),             $(output_dir)/$(test).verilator.out)
exec_simv = ./$(CONFIG)-sim
exec_simv_vcd = ./$(CONFIG)-sim-debug +vcd

$(output_dir)/%.verilator.dump: $(output_dir)/%.riscv
	riscv64-unknown-elf-objdump -DSl $< > $@

$(output_dir)/%.verilator.out: $(output_dir)/%.riscv $(CONFIG)-sim
	$(exec_simv) +max-cycles=$(timeout_cycles) +load=$< $(disasm) $@ && [ $$PIPESTATUS -eq 0 ]

.PRECIOUS: $(output_dir)/%.verilator.out

$(output_dir)/%.verilator.vcd: $(output_dir)/%.riscv $(CONFIG)-sim-debug
	$(exec_simv_vcd) +vcd_name=$@ +max-cycles=$(timeout_cycles) +load=$< $(disasm) $(patsubst %.vcd,%.out,$@) && [ $$PIPESTATUS -eq 0 ]

.PRECIOUS: $(output_dir)/%.verilator.vcd

$(output_dir)/%.verilator.vpd: $(output_dir)/%.riscv $(CONFIG)-sim-debug
	rm -rf $(patsubst %.vpd,%.vcd,$@) && mkfifo $(patsubst %.vpd,%.vcd,$@)
	vcd2vpd $(patsubst %.vpd,%.vcd,$@) $@ > /dev/null &
	$(exec_simv_vcd) +vcd_name=$@ +max-cycles=$(timeout_cycles) +load=$< $(disasm) $(patsubst %.vpd,%.out,$@) && [ $$PIPESTATUS -eq 0 ]

.PRECIOUS: $(output_dir)/%.verilator.vpd

run-asm-tests:      $(asm_tests_out)
run-bmark-tests:    $(bmarks_out)
run-tag-tests:      $(asm_tag_out)
run-tagcache-tests: $(asm_tagcache_out)

run: run-asm-tests run-bmarks-test

.PHONY: run-asm-tests run-bmarks-test run
junk += $(output_dir)

#--------------------------------------------------------------------
# clean up
#--------------------------------------------------------------------

clean:
	rm -rf $(junk)

.PHONY: clean
