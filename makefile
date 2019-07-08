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
  RULE    = FLAP
else
  DOBJ = exe/obj/
  DMOD = exe/mod/
  DEXE = exe/
  RULE = $(DEXE)flap_test_basic $(DEXE)flap_test_choices_logical $(DEXE)flap_test_nested $(DEXE)flap_test_string $(DEXE)flap_test_hidden $(DEXE)flap_test_minimal
endif
DSRC = src/
LIBS =
ifeq "$(COMPILER)" "gnu"
  FC    = gfortran
  OPTSC = -cpp -c -frealloc-lhs -O2  -J $(DMOD)
  OPTSL = -J $(DMOD)
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
COTEXT = "Compile $(<F)"
LITEXT = "Assemble $@"
RUTEXT = "Executed rule $@"

firsrule: $(RULE)

#building rules
$(DEXE)flap_test_basic: $(MKDIRS) $(DOBJ)flap_test_basic.o
	@rm -f $(filter-out $(DOBJ)flap_test_basic.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) flap_test_basic

$(DEXE)flap_test_choices_logical: $(MKDIRS) $(DOBJ)flap_test_choices_logical.o
	@rm -f $(filter-out $(DOBJ)flap_test_choices_logical.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) flap_test_choices_logical

$(DEXE)flap_test_nested: $(MKDIRS) $(DOBJ)flap_test_nested.o
	@rm -f $(filter-out $(DOBJ)flap_test_nested.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) flap_test_nested

$(DEXE)flap_test_string: $(MKDIRS) $(DOBJ)flap_test_string.o
	@rm -f $(filter-out $(DOBJ)flap_test_string.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) flap_test_string

$(DEXE)flap_test_hidden: $(MKDIRS) $(DOBJ)flap_test_hidden.o
	@rm -f $(filter-out $(DOBJ)flap_test_hidden.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) flap_test_hidden

$(DEXE)flap_test_minimal: $(MKDIRS) $(DOBJ)flap_test_minimal.o
	@rm -f $(filter-out $(DOBJ)flap_test_minimal.o,$(EXESOBJ))
	@echo $(LITEXT)
	@$(FC) $(OPTSL) $(DOBJ)*.o $(LIBS) -o $@
EXES := $(EXES) flap_test_minimal

FLAP: $(MKDIRS) $(DOBJ)flap.o
	@echo $(LITEXT)
	@$(MAKELIB)

#compiling rules
$(DOBJ)flap_command_line_interface_t.o: src/lib/flap_command_line_interface_t.F90 \
	$(DOBJ)flap_command_line_argument_t.o \
	$(DOBJ)flap_command_line_arguments_group_t.o \
	$(DOBJ)flap_object_t.o \
	$(DOBJ)flap_utils_m.o \
	$(DOBJ)penf.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_command_line_arguments_group_t.o: src/lib/flap_command_line_arguments_group_t.f90 \
	$(DOBJ)flap_command_line_argument_t.o \
	$(DOBJ)flap_object_t.o \
	$(DOBJ)penf.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_utils_m.o: src/lib/flap_utils_m.f90 \
	$(DOBJ)penf.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_command_line_argument_t.o: src/lib/flap_command_line_argument_t.F90 \
	$(DOBJ)flap_object_t.o \
	$(DOBJ)flap_utils_m.o \
	$(DOBJ)penf.o \
	$(DOBJ)face.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_object_t.o: src/lib/flap_object_t.f90 \
	$(DOBJ)penf.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap.o: src/lib/flap.f90 \
	$(DOBJ)flap_command_line_argument_t.o \
	$(DOBJ)flap_command_line_arguments_group_t.o \
	$(DOBJ)flap_command_line_interface_t.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)penf_b_size.o: src/third_party/PENF/src/lib/penf_b_size.F90 \
	$(DOBJ)penf_global_parameters_variables.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)penf.o: src/third_party/PENF/src/lib/penf.F90 \
	$(DOBJ)penf_global_parameters_variables.o \
	$(DOBJ)penf_b_size.o \
	$(DOBJ)penf_stringify.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)penf_stringify.o: src/third_party/PENF/src/lib/penf_stringify.F90 \
	$(DOBJ)penf_b_size.o \
	$(DOBJ)penf_global_parameters_variables.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)penf_global_parameters_variables.o: src/third_party/PENF/src/lib/penf_global_parameters_variables.F90
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)face.o: src/third_party/FACE/src/lib/face.F90
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_test_nested.o: src/tests/flap_test_nested.f90 \
	$(DOBJ)flap.o \
	$(DOBJ)penf.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_test_hidden.o: src/tests/flap_test_hidden.f90 \
	$(DOBJ)flap.o \
	$(DOBJ)penf.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_test_minimal.o: src/tests/flap_test_minimal.f90 \
	$(DOBJ)flap.o \
	$(DOBJ)penf.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_test_choices_logical.o: src/tests/flap_test_choices_logical.f90 \
	$(DOBJ)flap.o \
	$(DOBJ)penf.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_test_string.o: src/tests/flap_test_string.f90 \
	$(DOBJ)flap.o \
	$(DOBJ)penf.o
	@echo $(COTEXT)
	@$(FC) $(OPTSC)  $< -o $@

$(DOBJ)flap_test_basic.o: src/tests/flap_test_basic.f90 \
	$(DOBJ)flap.o \
	$(DOBJ)penf.o
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
