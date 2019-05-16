all:
	vivado -mode batch -source tcl/run.tcl
	mkdir -p ${BOARD}/ip
	cp -r ${BOARD}/${PROJECT}.srcs/sources_1/ip/${PROJECT}/* ${BOARD}/ip/.
	cp ${BOARD}/${PROJECT}.runs/${PROJECT}_synth_1/${PROJECT}.dcp ${BOARD}/ip/.

gui:
	vivado -mode gui -source tcl/run.tcl &

clean:
	rm -rf ${BOARD}/ip/*
	mkdir -p ${BOARD}/ip
	rm -rf ${BOARD}/${PROJECT}.*
	rm -rf component.xml
	rm -rf vivado*.jou
	rm -rf vivado*.log
	rm -rf vivado*.str
	rm -rf xgui
	rm -rf .Xil
