#!/usr/bin/make

#main building variables
DSRC    = src/
DOBJ    = tests/obj/
DMOD    = tests/mod/
DEXE    = tests/
LIBS    =
FC      = gfortran
OPTSC   =  -cpp -c -frealloc-lhs -O2  -J Test_Driver/mod/
OPTSL   =  -J tests/mod/
VPATH   = $(DSRC) $(DOBJ) $(DMOD) external/IR_Precision/
MKDIRS  = $(DOBJ) $(DMOD) $(DEXE)
LCEXES  = $(shell echo $(EXES) | tr '[:upper:]' '[:lower:]')
EXESPO  = $(addsuffix .o,$(LCEXES))
EXESOBJ = $(DOBJ)test_basic.o $(DOBJ)test_nested.o $(DOBJ)test_string.o $(DOBJ)test_choices_logical.o

#auxiliary variables
COTEXT  = "Compiling $(<F)"
LITEXT  = "Assembling $@"

all: $(DEXE)test_basic $(DEXE)test_nested $(DEXE)test_string $(DEXE)test_choices_logical

#building rules
$(DEXE)test_basic: $(MKDIRS) $(DOBJ)test_basic.o
	@rm -f $(filter-out $(DOBJ)test_basic.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@

$(DEXE)test_nested: $(MKDIRS) $(DOBJ)test_nested.o
	@rm -f $(filter-out $(DOBJ)test_nested.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@

$(DEXE)test_string: $(MKDIRS) $(DOBJ)test_string.o
	@rm -f $(filter-out $(DOBJ)test_string.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@

$(DEXE)test_choices_logical: $(MKDIRS) $(DOBJ)test_choices_logical.o
	@rm -f $(filter-out $(DOBJ)test_choices_logical.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@

EXES := $(EXES) $(DEXE)test_basic $(DEXE)test_nested $(DEXE)test_string $(DEXE)test_choices_logical

#compiling rules
$(DOBJ)data_type_command_line_interface.o: src/lib/Data_Type_Command_Line_Interface.F90 \
	$(DOBJ)ir_precision.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)ir_precision.o: src/lib/IR_Precision.f90
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_basic.o: src/tests/test_basic.f90 \
	$(DOBJ)ir_precision.o \
	$(DOBJ)data_type_command_line_interface.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_nested.o: src/tests/test_nested.f90 \
	$(DOBJ)ir_precision.o \
	$(DOBJ)data_type_command_line_interface.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_string.o: src/tests/test_string.f90 \
	$(DOBJ)ir_precision.o \
	$(DOBJ)data_type_command_line_interface.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_choices_logical.o: src/tests/test_choices_logical.f90 \
	$(DOBJ)ir_precision.o \
	$(DOBJ)data_type_command_line_interface.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

default: $(EXES)
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
