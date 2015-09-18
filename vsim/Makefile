# See LICENSE for license details.

#--------------------------------------------------------------------
# global define
#--------------------------------------------------------------------

default: all

base_dir = $(abspath ..)
generated_dir = $(abspath ./generated-src)
mem_gen = $(abspath ./vlsi_mem_gen)

sim_dir = .
output_dir = $(sim_dir)/output

BACKEND ?= lowrisc_chip.LowRISCBackend
CONFIG ?= DefaultConfig

include $(base_dir)/Makefrag

.PHONY: default all

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

# Verilog sources

sim_vsrcs = \
	$(generated_dir)/$(MODEL).$(CONFIG).v \
	$(generated_dir)/consts.$(CONFIG).vh \

#--------------------------------------------------------------------
# Build Verilog
#--------------------------------------------------------------------

verilog: $(sim_vsrcs)

$(generated_dir)/$(MODEL).$(CONFIG).v: $(chisel_srcs)
	cd $(base_dir) && mkdir -p $(generated_dir) && $(SBT) "run $(CHISEL_ARGS) --configDump --noInlineMem"
	cd $(generated_dir) && \
	if [ -a $(MODEL).$(CONFIG).conf ]; then \
	  $(mem_gen) $(generated_dir)/$(MODEL).$(CONFIG).conf >> $(generated_dir)/$(MODEL).$(CONFIG).v; \
	fi && \
	sed -i.bak "s|fwrite(32'h80000002, |display(|" $(generated_dir)/$(MODEL).$(CONFIG).v

$(generated_dir)/consts.$(CONFIG).vh: $(generated_dir)/$(MODEL).$(CONFIG).v
	echo "\`ifndef CONST_VH" > $@
	echo "\`define CONST_VH" >> $@
	sed -r 's/\(([A-Za-z0-9_]+),([A-Za-z0-9_]+)\)/`define \1 \2/' $(patsubst %.v,%.prm,$<) >> $@
	echo "\`endif // CONST_VH" >> $@

.PHONY: verilog

#--------------------------------------------------------------------
# Build rules (verilator)
#--------------------------------------------------------------------
veri = verilator
tb_top = chip_top

veri_flags = \
	+incdir+$(generated_dir) \
	+incdir+$(base_dir)/vsrc \
	+incdir+$(base_dir)/csrc/veri \
	--top-module $(tb_top) \
	--unroll-count 256 \
	--trace \
	-Wno-lint -Wno-style -Wno-STMTDLY \
	--exe \
	--Mdir $(sim_dir)/verilator

# remove optimization if compilation takes too long or run out of memory
veri_opt_flags = -O3 -CFLAGS "-O1"

veri_vsrcs = \
	$(base_dir)/vsrc/chip_top.sv \
	$(generated_dir)/$(MODEL).$(CONFIG).v \
	$(base_dir)/vsrc/axi_ram_behav.sv \
	$(base_dir)/vsrc/host_behav.sv \
	$(base_dir)/socip/nasti/channel.sv \

veri_csrcs = \
	$(base_dir)/csrc/veri/dpi_ram_behav.cpp \
	$(base_dir)/csrc/veri/dpi_host_behav.cpp \
	$(base_dir)/csrc/veri/veri_top.cc \

#--------------------------------------------------------------------
# Build the simulator (verilator)
#--------------------------------------------------------------------
verilator: verilator.log
verilator.log: $(sim_vsrcs) $(veri_vsrcs) $(veri_csrcs)
	rm -fr $(sim_dir)/verilator
	$(veri) --cc $(veri_vsrcs) $(veri_csrcs) $(veri_flags) $(veri_opt_flags) -o ../$(CONFIG)-sim | tee $@

sim: $(CONFIG)-sim
$(CONFIG)-sim: verilator.log
	cd verilator && make -f V$(tb_top).mk

verilator.debug.log: $(sim_vsrcs) $(veri_vsrcs) $(veri_csrcs)
	rm -fr $(sim_dir)/verilator
	$(veri) --cc $(veri_vsrcs) $(veri_csrcs) $(veri_flags) -CFLAGS "-g -DDELAY_EXIT" -o ../$(CONFIG)-sim-debug | tee $@

sim-debug: $(CONFIG)-sim-debug
$(CONFIG)-sim-debug: verilator.debug.log
	cd verilator && make -f V$(tb_top).mk

all: sim

.PHONY: verilator sim

junk += $(generated_dir) $(CONFIG)-sim verilator

#--------------------------------------------------------------------
# Test cases
#--------------------------------------------------------------------
rv32ui = simple add addi and andi auipc beq bge bgeu blt bltu bne fence_i \
	j jal jalr lb lbu lh lhu lui lw or ori sb sh sw sll slli \
    slt slti sra srai srl srli sub xor xori

rv32um = mul mulh mulhsu mulhu div divu rem remu

rv32ua = amoadd_w amoand_w amoor_w amoxor_w amoswap_w amomax_w amomaxu_w amomin_w amominu_w

rv64ui = addw addiw ld lwu sd slliw sllw sltiu sltu sraiw sraw srliw srlw subw $(rv32ui)

rv64um = divuw divw mulw remuw remw $(rv32um)

rv64ua = amoadd_d amoand_d amoor_d amoxor_d amoswap_d amomax_d amomaxu_d amomin_d amominu_d $(rv32ua)

rv64uf = ldst move fsgnj fcmp fcvt fcvt_w fclass fadd fdiv fmin fmadd structural

rv64si = csr illegal ma_fetch ma_addr scall sbreak wfi

rv64mi = csr mcsr wfi dirty illegal ma_addr ma_fetch sbreak scall timer

bmarks = median multiply qsort towers vvadd mm dhrystone spmv mt-vvadd mt-matmul

#--------------------------------------------------------------------
asm_p_tests  += $(addprefix rv64ui-p-, $(rv64ui))  $(addprefix rv64ui-p-, $(rv64um))  $(addprefix rv64ui-p-, $(rv64ua))
asm_pt_tests += $(addprefix rv64ui-pt-, $(rv64ui)) $(addprefix rv64ui-pt-, $(rv64um)) $(addprefix rv64ui-pt-, $(rv64ua))
asm_pm_tests += $(addprefix rv64ui-pm-, $(rv64ui)) $(addprefix rv64ui-pm-, $(rv64um)) $(addprefix rv64ui-pm-, $(rv64ua))
asm_v_tests  += $(addprefix rv64ui-v-, $(rv64ui))  $(addprefix rv64ui-v-, $(rv64um))  $(addprefix rv64ui-v-, $(rv64ua))

asm_p_tests  += $(addprefix rv64uf-p-, $(rv64uf))
asm_pt_tests += $(addprefix rv64uf-pt-, $(rv64uf))
asm_v_tests  += $(addprefix rv64uf-v-, $(rv64uf))

asm_p_tests  += $(addprefix rv64si-p-, $(rv64si))

asm_p_tests  += $(addprefix rv64mi-p-, $(rv64mi))
asm_pm_tests += $(addprefix rv64mi-pm-, $(rv64mi))

bmarks_tests += $(addsuffix .riscv, $(bmarks))

#--------------------------------------------------------------------
riscv_test_asm_dir = $(base_dir)/riscv-tools/riscv-tests/isa
riscv_test_bmarks_dir = $(base_dir)/riscv-tools/riscv-tests/benchmarks

%.hex:
	$(MAKE) -C $(dir $@) $(notdir $@)

$(addprefix $(output_dir)/, $(addsuffix .hex, $(asm_p_tests) $(asm_pt_tests) $(asm_pm_tests) $(asm_v_tests))): $(output_dir)/%.hex: $(riscv_test_asm_dir)/%.hex
	mkdir -p $(output_dir)
	ln -fs $< $@

$(addprefix $(output_dir)/, $(addsuffix .hex, $(bmarks_tests))): $(output_dir)/%.hex: $(riscv_test_bmarks_dir)/%.hex
	mkdir -p $(output_dir)
	ln -fs $< $@

#--------------------------------------------------------------------
# Run (verilator)
#--------------------------------------------------------------------
asm_tests_out = $(foreach test, $(asm_p_tests) $(asm_v_tests), $(output_dir)/$(test).verilator.out)
bmarks_out = $(foreach test, $(bmarks_tests), $(output_dir)/$(test).verilator.out)
exec_simv = $(CONFIG)-sim
exec_simv_vcd = $(CONFIG)-sim-debug +vcd

$(output_dir)/%.verilator.out: $(output_dir)/%.hex $(CONFIG)-sim
	$(exec_simv) +max-cycles=$(timeout_cycles) +load=$< $(disasm) $@ && [ $$PIPESTATUS -eq 0 ]

.PRECIOUS: $(output_dir)/%.verilator.out

$(output_dir)/%.verilator.vcd: $(output_dir)/%.hex $(CONFIG)-sim-debug
	$(exec_simv_vcd) +vcd_name=$@ +max-cycles=$(timeout_cycles) +load=$< $(disasm) $(patsubst %.vcd,%.out,$@) && [ $$PIPESTATUS -eq 0 ]

.PRECIOUS: $(output_dir)/%.verilator.vcd

$(output_dir)/%.verilator.vpd: $(output_dir)/%.hex $(CONFIG)-sim-debug
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
