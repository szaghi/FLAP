#!/usr/bin/make

# defaults
STATIC = no
COMPILER = gnu

#main building variables
ifeq "$(STATIC)" "yes"
  DOBJ    = static/obj/
  DMOD    = static/mod/
  DEXE    = static/
  MAKELIB = ar -rcs $(DEXE)libflap.a $(DOBJ)*.o ; ranlib $(DEXE)libflap.a
else
  DOBJ = tests/obj/
  DMOD = tests/mod/
  DEXE = tests/
endif
DSRC = src/
LIBS =
ifeq "$(COMPILER)" "gnu"
  FC    = gfortran
  OPTSC = -cpp -c -frealloc-lhs -O2  -J $(DMOD) -static
  OPTSL = -J $(DMOD) -static
endif
ifeq "$(COMPILER)" "ibm"
  FC    = bgxlf2008_r
  OPTSC = -c -O2 -qmoddir=$(DMOD) -I$(DMOD)
  OPTSL = -qmoddir=$(DMOD) -I$(DMOD)
endif
VPATH   = $(DSRC) $(DOBJ) $(DMOD)
MKDIRS  = $(DOBJ) $(DMOD) $(DEXE)
LCEXES  = $(shell echo $(EXES) | tr '[:upper:]' '[:lower:]')
EXESPO  = $(addsuffix .o,$(LCEXES))
EXESOBJ = $(addprefix $(DOBJ),$(EXESPO))

#auxiliary variables
COTEXT = "Compiling $(<F)"
LITEXT = "Assembling $@"

all: $(DEXE)test_basic $(DEXE)test_choices_logical $(DEXE)test_nested $(DEXE)test_string

#building rules
$(DEXE)test_basic: $(MKDIRS) $(DOBJ)test_basic.o
	@rm -f $(filter-out $(DOBJ)test_basic.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) test_basic

$(DEXE)test_choices_logical: $(MKDIRS) $(DOBJ)test_choices_logical.o
	@rm -f $(filter-out $(DOBJ)test_choices_logical.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) test_choices_logical

$(DEXE)test_nested: $(MKDIRS) $(DOBJ)test_nested.o
	@rm -f $(filter-out $(DOBJ)test_nested.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) test_nested

$(DEXE)test_string: $(MKDIRS) $(DOBJ)test_string.o
	@rm -f $(filter-out $(DOBJ)test_string.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) test_string

FLAP: $(MKDIRS) $(DOBJ)flap.o
	@echo $(LITEXT)
	@$(MAKELIB)

#compiling rules
$(DOBJ)flap_command_line_interface_t.o: src/lib/flap_command_line_interface_t.F90 \
	$(DOBJ)flap_command_line_argument_t.o \
	$(DOBJ)flap_command_line_arguments_group_t.o \
	$(DOBJ)flap_object_t.o \
	$(DOBJ)flap_utils_m.o \
	$(DOBJ)ir_precision.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_command_line_arguments_group_t.o: src/lib/flap_command_line_arguments_group_t.f90 \
	$(DOBJ)flap_command_line_argument_t.o \
	$(DOBJ)flap_object_t.o \
	$(DOBJ)ir_precision.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_utils_m.o: src/lib/flap_utils_m.f90 \
	$(DOBJ)ir_precision.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_command_line_argument_t.o: src/lib/flap_command_line_argument_t.F90 \
	$(DOBJ)flap_object_t.o \
	$(DOBJ)flap_utils_m.o \
	$(DOBJ)ir_precision.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_object_t.o: src/lib/flap_object_t.f90 \
	$(DOBJ)ir_precision.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap.o: src/lib/flap.f90 \
	$(DOBJ)flap_command_line_argument_t.o \
	$(DOBJ)flap_command_line_arguments_group_t.o \
	$(DOBJ)flap_command_line_interface_t.o \
	$(DOBJ)ir_precision.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)ir_precision.o: src/third_party/IR_Precision/src/IR_Precision.f90
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_driver.o: src/third_party/IR_Precision/src/Test_Driver.f90 \
	$(DOBJ)ir_precision.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_nested.o: src/tests/test_nested.f90 \
	$(DOBJ)ir_precision.o \
	$(DOBJ)flap.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_choices_logical.o: src/tests/test_choices_logical.f90 \
	$(DOBJ)ir_precision.o \
	$(DOBJ)flap.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_string.o: src/tests/test_string.f90 \
	$(DOBJ)ir_precision.o \
	$(DOBJ)flap.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)test_basic.o: src/tests/test_basic.f90 \
	$(DOBJ)ir_precision.o \
	$(DOBJ)flap.o
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
