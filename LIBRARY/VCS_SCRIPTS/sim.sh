vcs -sverilog OLD_TB \
OLD_RTL_SOURCES-debug_acc+pp+dmptf -debug_region+cell+encrypt +lint=TFIPC-L -full64 +vcd +vcdpluson +plusarg_save
./simv -gui=dve +vcs+finish+OLD_SIM_TIME000