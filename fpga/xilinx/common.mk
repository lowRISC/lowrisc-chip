all:
	vivado -mode batch -source tcl/run.tcl
	mkdir -p ip
	cp -r ${BOARD}/${PROJECT}.srcs/sources_1/ip/${PROJECT}/* ip/.
	cp ${BOARD}/${PROJECT}.runs/${PROJECT}_synth_1/${PROJECT}.dcp ip/.

gui:
	vivado -mode gui -source tcl/run.tcl &

clean:
	rm -rf ip/*
	mkdir -p ip
	rm -rf ${BOARD}/${PROJECT}.*
	rm -rf component.xml
	rm -rf vivado*.jou
	rm -rf vivado*.log
	rm -rf vivado*.str
	rm -rf xgui
	rm -rf .Xil
