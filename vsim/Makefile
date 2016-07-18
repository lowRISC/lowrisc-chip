# See LICENSE for license details.

# check Verilator environment variable
ifndef VERILATOR_ROOT
$(error Please set environment for the Verilator simulator)
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

glip_dir = $(base_dir)/opensocdebug/glip/src
osd_dir = $(base_dir)/opensocdebug/hardware

BACKEND ?= lowrisc_chip.LowRISCBackend
#CONFIG ?= DebugConfig
CONFIG ?= DefaultConfig

include $(base_dir)/Makefrag

.PHONY: default

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

lowrisc_srcs = \
	$(generated_dir)/$(MODEL).$(CONFIG).v \

lowrisc_headers = \
	$(generated_dir)/consts.vh \
	$(generated_dir)/dev_map.vh \
	$(generated_dir)/dev_map.h \

verilog_srcs = \
	$(osd_dir)/interfaces/common/dii_channel.sv \
	$(base_dir)/src/main/verilog/chip_top.sv \
	$(base_dir)/socip/nasti/channel.sv \
	$(base_dir)/socip/nasti/lite_nasti_reader.sv \
	$(base_dir)/socip/nasti/lite_nasti_writer.sv \
	$(base_dir)/socip/nasti/nasti_buf.sv \
	$(base_dir)/socip/nasti/nasti_combiner.sv \
	$(base_dir)/socip/nasti/nasti_crossbar.sv \
	$(base_dir)/socip/nasti/nasti_demux.sv \
	$(base_dir)/socip/nasti/nasti_lite_bridge.sv \
	$(base_dir)/socip/nasti/nasti_lite_reader.sv \
	$(base_dir)/socip/nasti/nasti_lite_writer.sv \
	$(base_dir)/socip/nasti/nasti_mux.sv \
	$(base_dir)/socip/nasti/nasti_slicer.sv \
	$(base_dir)/socip/util/arbiter.sv \
	$(base_dir)/src/main/verilog/debug_system.sv \
	$(osd_dir)/interconnect/common/debug_ring_expand.sv \
	$(osd_dir)/interconnect/common/ring_router.sv \
	$(osd_dir)/interconnect/common/ring_router_mux.sv \
	$(osd_dir)/interconnect/common/ring_router_mux_rr.sv \
	$(osd_dir)/interconnect/common/ring_router_demux.sv \
	$(osd_dir)/blocks/buffer/common/dii_buffer.sv \
	$(osd_dir)/blocks/buffer/common/osd_fifo.sv \
	$(osd_dir)/blocks/timestamp/common/osd_timestamp.sv \
	$(osd_dir)/blocks/tracepacket/common/osd_trace_packetization.sv \
	$(osd_dir)/blocks/tracesample/common/osd_tracesample.sv \
	$(osd_dir)/blocks/regaccess/common/osd_regaccess.sv \
	$(osd_dir)/blocks/regaccess/common/osd_regaccess_demux.sv \
	$(osd_dir)/blocks/regaccess/common/osd_regaccess_layer.sv \
	$(osd_dir)/modules/dem_uart/common/osd_dem_uart.sv \
	$(osd_dir)/modules/dem_uart/common/osd_dem_uart_16550.sv \
	$(osd_dir)/modules/dem_uart/common/osd_dem_uart_nasti.sv \
	$(osd_dir)/modules/him/common/osd_him.sv \
	$(osd_dir)/modules/scm/common/osd_scm.sv \
	$(osd_dir)/modules/mam/common/osd_mam.sv \
	$(osd_dir)/modules/stm/common/osd_stm.sv \
	$(osd_dir)/modules/ctm/common/osd_ctm.sv \
	$(glip_dir)/common/logic/interface/glip_channel.sv \

verilog_headers = \
	$(base_dir)/src/main/verilog/config.vh \

test_verilog_srcs = \
	$(base_dir)/src/test/verilog/host_behav.sv \
	$(base_dir)/src/test/verilog/nasti_ram_behav.sv \
	$(glip_dir)/backend_tcp/logic/dpi/glip_tcp_toplevel.sv \

test_cxx_srcs = \
	$(base_dir)/src/test/cxx/common/globals.cpp \
	$(base_dir)/src/test/cxx/common/loadelf.cpp \
	$(base_dir)/src/test/cxx/common/dpi_ram_behav.cpp \
	$(base_dir)/src/test/cxx/common/dpi_host_behav.cpp \
	$(base_dir)/opensocdebug/glip/src/backend_tcp/logic/dpi/glip_tcp_dpi.cpp \
	$(base_dir)/opensocdebug/glip/src/backend_tcp/logic/dpi/GlipTcp.cpp \
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

include $(base_dir)/Makefrag-build

.PHONY: verilog
junk += $(generated_dir)

#--------------------------------------------------------------------
# Build rules (verilator)
#--------------------------------------------------------------------
veri = verilator
tb_top = chip_top

veri_flags = \
	-DVERILATOR_GCC \
	+incdir+$(generated_dir) \
	+incdir+$(base_dir)/src/main/verilog \
	--top-module $(tb_top) \
	--unroll-count 256 \
	--trace \
	-Wno-lint -Wno-style -Wno-STMTDLY -Wno-ASSIGNIN\
	-CFLAGS "-std=c++11" \
	-CFLAGS "-I$(base_dir)/src/test/cxx/common -I$(base_dir)/src/test/cxx/veri -I$(glip_dir)/backend_tcp/logic/dpi" \
        -LDFLAGS "-pthread" \
	--exe \
	--Mdir $(sim_dir)/verilator

# remove optimization if compilation takes too long or run out of memory
#veri_opt_flags = -O3 -CFLAGS "-O1"
veri_opt_flags =


#--------------------------------------------------------------------
# Build the simulator (verilator)
#--------------------------------------------------------------------
verilator: verilator.log
verilator.log: $(lowrisc_srcs) $(lowrisc_headers) $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(test_cxx_srcs) $(test_cxx_headers)
	rm -fr $(sim_dir)/verilator
	$(veri) --cc $(lowrisc_srcs) $(verilog_srcs) $(test_verilog_srcs) $(test_cxx_srcs) $(veri_flags) $(veri_opt_flags) -o ../$(CONFIG)-sim 2>&1 | tee $@

sim: $(CONFIG)-sim
$(CONFIG)-sim: verilator.log
	cd verilator && make -f V$(tb_top).mk

verilator.debug.log: $(lowrisc_srcs) $(lowrisc_headers) $(verilog_srcs) $(verilog_headers) $(test_verilog_srcs) $(test_cxx_srcs) $(test_cxx_headers)
	rm -fr $(sim_dir)/verilator
	$(veri) --cc $(lowrisc_srcs) $(verilog_srcs) $(test_verilog_srcs) $(test_cxx_srcs) $(veri_flags) -CFLAGS "-g -DDELAY_EXIT -DVERBOSE_MEMORY" -o ../$(CONFIG)-sim-debug | tee $@

sim-debug: $(CONFIG)-sim-debug
$(CONFIG)-sim-debug: verilator.debug.log
	cd verilator && make -f V$(tb_top).mk

.PHONY: verilator sim

junk += $(generated_dir) $(CONFIG)-sim verilator verilator.log $(CONFIG)-sim-debug verilator.debug.log

#--------------------------------------------------------------------
# Test cases
#--------------------------------------------------------------------
rv32ui = simple add addi and andi auipc beq bge bgeu blt bltu bne fence_i \
         j jal jalr lb lbu lh lhu lui lw or ori sb sh sw sll slli \
         slt slti sra srai srl srli sub xor xori \

rv32um = mul mulh mulhsu mulhu div divu rem remu \

rv32ua = amoadd_w amoand_w amoor_w amoxor_w amoswap_w amomax_w amomaxu_w amomin_w amominu_w \

rv32si = csr ma_fetch scall sbreak wfi \

rv32mi = csr mcsr dirty illegal ma_addr ma_fetch sbreak scall \

rv64ui = $(rv32ui) addw addiw ld lwu sd slliw sllw sltiu sltu sraiw sraw srliw srlw subw \

rv64um = $(rv32um) divuw divw mulw remuw remw \

rv64ua = amoadd_d amoand_d amoor_d amoxor_d amoswap_d amomax_d amomaxu_d amomin_d amominu_d \

rv64uf = ldst move fsgnj fcmp fcvt fcvt_w fclass fadd fdiv fmin fmadd structural \

rv64si = $(rv32si)

rv64mi = $(rv32mi)

bmarks = median multiply qsort towers vvadd mm dhrystone spmv mt-vvadd mt-matmul

#--------------------------------------------------------------------
asm_p_tests  += $(addprefix rv64ui-p-, $(rv64ui))
asm_p_tests  += $(addprefix rv64ui-p-, $(rv64um))
asm_p_tests  += $(addprefix rv64ui-p-, $(rv64ua))
asm_p_tests  += $(addprefix rv64uf-p-, $(rv64uf))
asm_p_tests  += $(addprefix rv64si-p-, $(rv64si))
asm_p_tests  += $(addprefix rv64mi-p-, $(rv64mi))

asm_v_tests  += $(addprefix rv64ui-v-, $(rv64ui))
asm_v_tests  += $(addprefix rv64ui-v-, $(rv64um))
asm_v_tests  += $(addprefix rv64ui-v-, $(rv64ua))
asm_v_tests  += $(addprefix rv64uf-v-, $(rv64uf))

bmarks_tests += $(bmarks)

#--------------------------------------------------------------------
riscv_test_asm_dir = $(base_dir)/riscv-tools/riscv-tests/isa
riscv_test_bmarks_dir = $(base_dir)/riscv-tools/riscv-tests/benchmarks

$(addprefix $(output_dir)/, $(addsuffix .riscv, $(asm_p_tests) $(asm_v_tests))):
	mkdir -p $(output_dir)
	$(MAKE) -C $(riscv_test_asm_dir) $(basename $(notdir $@))
	ln -fs $(riscv_test_asm_dir)/$(basename $(notdir $@)) $@

$(addprefix $(output_dir)/, $(addsuffix .riscv, $(bmarks_tests))):
	mkdir -p $(output_dir)
	$(MAKE) -C $(riscv_test_bmarks_dir) $(basename $(notdir $@))
	ln -fs $(riscv_test_asm_dir)/$(basename $(notdir $@)) $@

#--------------------------------------------------------------------
# Run (verilator)
#--------------------------------------------------------------------
asm_tests_out = $(foreach test, $(asm_p_tests) $(asm_pt_tests) $(asm_v_tests), $(output_dir)/$(test).verilator.out)
bmarks_out = $(foreach test, $(bmarks_tests), $(output_dir)/$(test).verilator.out)
exec_simv = ./$(CONFIG)-sim
exec_simv_vcd = ./$(CONFIG)-sim-debug +vcd

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

run-asm-tests: $(asm_tests_out)
run-bmarks-test: $(bmarks_out)

run: run-asm-tests run-bmarks-test

.PHONY: run-asm-tests run-bmarks-test run
junk += $(output_dir)

#--------------------------------------------------------------------
# clean up
#--------------------------------------------------------------------

clean:
	rm -rf $(junk)

.PHONY: clean
