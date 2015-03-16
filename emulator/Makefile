base_dir = $(abspath ..)
sim_dir = .
output_dir = $(sim_dir)/output
tag_output_dir = $(sim_dir)/tag_output
PROJECT = lowrisc_chip
CONFIG ?= DefaultCPPConfig

all: emulator-$(CONFIG)
debug: emulator-$(CONFIG)-debug

include $(base_dir)/Makefrag

CXXFLAGS := $(CXXFLAGS) -std=c++11 -I$(RISCV)/include

CXXSRCS := emulator mm mm_dramsim2
CXXFLAGS := $(CXXFLAGS) -I$(base_dir)/csrc -I$(base_dir)/dramsim2

LDFLAGS := $(LDFLAGS) -L$(RISCV)/lib -Wl,-rpath,$(RISCV)/lib -L. -ldramsim -lfesvr -lpthread

OBJS := $(addsuffix .o,$(CXXSRCS) $(MODEL).$(CONFIG))
DEBUG_OBJS := $(addsuffix .debug.o,$(CXXSRCS) $(MODEL).$(CONFIG))

CHISEL_ARGS := $(MODEL) --W0W --noIoDebug --backend c --configInstance $(PROJECT).$(CONFIG) --targetDir emulator/generated-src
CHISEL_ARGS_DEBUG := $(CHISEL_ARGS)-debug --debug --vcd --ioDebug

generated-src/$(MODEL).$(CONFIG).h: $(chisel_srcs)
	cd $(base_dir) && $(SBT) "project $(PROJECT)" "elaborate $(CHISEL_ARGS)"

generated-src-debug/$(MODEL).$(CONFIG).h: $(chisel_srcs)
	cd $(base_dir) && $(SBT) "project $(PROJECT)" "elaborate $(CHISEL_ARGS_DEBUG)"

$(MODEL).$(CONFIG).o: %.o: generated-src/%.h
	$(MAKE) -j $(patsubst %.cpp,%.o,$(shell ls generated-src/$(MODEL).$(CONFIG)-*.cpp))
	$(LD) -r $(patsubst %.cpp,%.o,$(shell ls generated-src/$(MODEL).$(CONFIG)-*.cpp)) -o $@

$(MODEL).$(CONFIG).debug.o: %.debug.o: generated-src-debug/%.h
	$(MAKE) -j $(patsubst %.cpp,%.o,$(shell ls generated-src-debug/$(MODEL).$(CONFIG)-*.cpp))
	$(LD) -r $(patsubst %.cpp,%.o,$(shell ls generated-src-debug/$(MODEL).$(CONFIG)-*.cpp)) -o $@

$(wildcard generated-src/*.o): %.o: %.cpp generated-src/$(MODEL).$(CONFIG).h
	$(CXX) $(CXXFLAGS) -Igenerated-src -c -o $@ $<

$(wildcard generated-src-debug/*.o): %.o: %.cpp generated-src-debug/$(MODEL).$(CONFIG).h
	$(CXX) $(CXXFLAGS) -Igenerated-src-debug -c -o $@ $<

$(addsuffix .o,$(CXXSRCS)): %.o: $(base_dir)/csrc/%.cc $(base_dir)/csrc/*.h generated-src/$(MODEL).$(CONFIG).h
	$(CXX) $(CXXFLAGS) -include generated-src/$(MODEL).$(CONFIG).h -Igenerated-src -c -o $@ $<

$(addsuffix .debug.o,$(CXXSRCS)): %.debug.o: $(base_dir)/csrc/%.cc $(base_dir)/csrc/*.h generated-src-debug/$(MODEL).$(CONFIG).h
	$(CXX) $(CXXFLAGS) -include generated-src-debug/$(MODEL).$(CONFIG).h -Igenerated-src-debug -c -o $@ $<

emulator-$(CONFIG): $(OBJS) libdramsim.a
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS) $(LDFLAGS)

emulator-$(CONFIG)-debug: $(DEBUG_OBJS) libdramsim.a
	$(CXX) $(CXXFLAGS) -o $@ $(DEBUG_OBJS) $(LDFLAGS)

clean:
	rm -rf *.o *.a emulator-* emulator-*-debug generated-src generated-src-debug DVEfiles $(output_dir) $(tag_output_dir)

test:
	cd $(base_dir) && $(SBT) "~make $(CURDIR) run-fast $(CHISEL_ARGS)"

#--------------------------------------------------------------------
# Run assembly tests and benchmarks
#--------------------------------------------------------------------

$(output_dir)/%.run: $(output_dir)/%.hex emulator-$(CONFIG)
	./emulator-$(CONFIG) +dramsim +max-cycles=$(timeout_cycles) +loadmem=$< none 2> /dev/null 2> $@ && [ $$PIPESTATUS -eq 0 ]

$(output_dir)/%.out: $(output_dir)/%.hex emulator-$(CONFIG)
	./emulator-$(CONFIG) +dramsim +max-cycles=$(timeout_cycles) +verbose +loadmem=$< none $(disasm) $@ && [ $$PIPESTATUS -eq 0 ]

$(output_dir)/%.vcd: $(output_dir)/%.hex emulator-$(CONFIG)-debug
	./emulator-$(CONFIG)-debug +dramsim +max-cycles=$(timeout_cycles) +verbose -v$@ +loadmem=$< none $(disasm) $(patsubst %.vcd,%.out,$@) && [ $$PIPESTATUS -eq 0 ]

$(output_dir)/%.vpd: $(output_dir)/%.hex emulator-$(CONFIG)-debug
	rm -rf $@.vcd && mkfifo $@.vcd
	vcd2vpd $@.vcd $@ > /dev/null &
	./emulator-$(CONFIG)-debug +dramsim +max-cycles=$(timeout_cycles) +verbose -v$@.vcd +loadmem=$< none $(disasm) $(patsubst %.vpd,%.out,$@) && [ $$PIPESTATUS -eq 0 ]

$(tag_output_dir)/%.out: $(tag_output_dir)/% emulator-$(CONFIG)
	./emulator-$(CONFIG) +dramsim +max-cycles=$(timeout_cycles) +verbose pk $< none $(disasm) $@ && [ $$PIPESTATUS -eq 0 ]

$(tag_output_dir)/%.vcd: $(tag_output_dir)/% emulator-$(CONFIG)-debug
	./emulator-$(CONFIG)-debug +dramsim +max-cycles=$(timeout_cycles) +verbose -v$@ pk $< none $(disasm) $(patsubst %.vcd,%.out,$@) && [ $$PIPESTATUS -eq 0 ]

$(tag_output_dir)/%.vpd: $(tag_output_dir)/% emulator-$(CONFIG)-debug
	rm -rf $@.vcd && mkfifo $@.vcd
	vcd2vpd $@.vcd $@ > /dev/null &
	./emulator-$(CONFIG)-debug +dramsim +max-cycles=$(timeout_cycles) +verbose -v$@.vcd pk $< none $(disasm) $(patsubst %.vpd,%.out,$@) && [ $$PIPESTATUS -eq 0 ]


run-asm-tests: $(addprefix $(output_dir)/, $(addsuffix .out, $(asm_p_tests) $(asm_v_tests)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $^; echo;
run-bmarks-test: $(addprefix $(output_dir)/, $(addsuffix .out, $(bmarks)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $^; echo;
run-mt-tests: $(addprefix $(output_dir)/, $(addsuffix .out, $(mt_bmarks)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $^; echo;
run-tag-tests: $(addprefix $(tag_output_dir)/, $(addsuffix .out, $(tag_tests)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $^; echo;

run-asm-tests-vcd: $(addprefix $(output_dir)/, $(addsuffix .vcd, $(asm_p_tests) $(asm_v_tests)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $(patsubst %.vcd,%.out,$^); echo;
run-bmarks-test-vcd: $(addprefix $(output_dir)/, $(addsuffix .vcd, $(bmarks)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $(patsubst %.vcd,%.out,$^); echo;
run-mt-tests-vcd: $(addprefix $(output_dir)/, $(addsuffix .vcd, $(mt_bmarks)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $(patsubst %.vcd,%.out,$^); echo;
run-tag-tests-vcd: $(addprefix $(tag_output_dir)/, $(addsuffix .vcd, $(tag_tests)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $(patsubst %.vcd,%.out,$^); echo;

run-asm-tests-vpd: $(addprefix $(output_dir)/, $(addsuffix .vpd, $(asm_p_tests) $(asm_v_tests)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $(patsubst %.vpd,%.out,$^); echo;
run-bmarks-test-vpd: $(addprefix $(output_dir)/, $(addsuffix .vpd, $(bmarks)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $(patsubst %.vpd,%.out,$^); echo;
run-mt-tests-vpd: $(addprefix $(output_dir)/, $(addsuffix .vpd, $(mt_bmarks)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $(patsubst %.vpd,%.out,$^); echo;
run-tag-tests-vpd: $(addprefix $(tag_output_dir)/, $(addsuffix .vpd, $(tag_tests)))
	@echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' $(patsubst %.vpd,%.out,$^); echo;

# UCB use only
-include Makefrag-refchip

run: run-asm-tests run-bmarks-test run-tag-tests
run-vcd: run-asm-tests-vcd run-bmarks-test-vcd run-tag-tests-vcd
run-vpd: run-asm-tests-vpd run-bmarks-test-vpd run-tag-tests-vpd
run-fast: $(addprefix $(output_dir)/, $(addsuffix .run, $(asm_p_tests) $(asm_v_tests) $(bmarks)))

.PHONY: run-asm-tests run-bmarks-test run-mt-tests run-tag-tests
.PHONY: run-asm-tests-vcd run-bmarks-test-vcd run-mt-tests-vcd run-tag-tests-vcd
.PHONY: run-asm-tests-vpd run-bmarks-test-vpd run-mt-tests-vpd run-tag-tests-vpd
.PHONY: run run-vcd run-vpd run-fast
