#!/usr/bin/make

#main building variables
DSRC    = src/
DOBJ    = Test_Driver/obj/
DMOD    = Test_Driver/mod/
DEXE    = Test_Driver/
LIBS    =
FC      = gfortran
OPTSC   =  -cpp -c -frealloc-lhs -O2  -J Test_Driver/mod/
OPTSL   =  -J Test_Driver/mod/
VPATH   = $(DSRC) $(DOBJ) $(DMOD) src/IR_Precision/src/
MKDIRS  = $(DOBJ) $(DMOD) $(DEXE)
LCEXES  = $(shell echo $(EXES) | tr '[:upper:]' '[:lower:]')
EXESPO  = $(addsuffix .o,$(LCEXES))
EXESOBJ = $(addprefix $(DOBJ),$(EXESPO))

#auxiliary variables
COTEXT  = "Compiling $(<F)"
LITEXT  = "Assembling $@"

#building rules
$(DEXE)TEST_DRIVER: $(MKDIRS) $(DOBJ)test_driver.o
	@rm -f $(filter-out $(DOBJ)test_driver.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) TEST_DRIVER

#compiling rules
$(DOBJ)data_type_command_line_interface.o: src/Data_Type_Command_Line_Interface.F90 \
	$(DOBJ)ir_precision.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)ir_precision.o: src/IR_Precision/src/IR_Precision.f90
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_driver.o: src/Test_Driver.f90 \
	$(DOBJ)ir_precision.o \
	$(DOBJ)data_type_command_line_interface.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

#phony auxiliary rules
.PHONY : $(MKDIRS)
$(MKDIRS):
	@mkdir -p $@
.PHONY : cleanobj
cleanobj:
	@echo deleting objects
	@rm -fr $(DOBJ)
.PHONY : cleanmod
cleanmod:
	@echo deleting mods
	@rm -fr $(DMOD)
.PHONY : cleanexe
cleanexe:
	@echo deleting exes
	@rm -f $(addprefix $(DEXE),$(EXES))
.PHONY : clean
clean: cleanobj cleanmod
.PHONY : cleanall
cleanall: clean cleanexe
