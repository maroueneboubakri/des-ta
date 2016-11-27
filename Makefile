#
# Copyright (C) Telecom ParisTech
# 
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
#

SHELL		:= /bin/bash

CC		:= gcc
CFLAGS		:= -Wall -c
OPT		:= -O3
PYCFLAGS	:= -std=c99 -fPIC -DPYTHON_LIB $(shell python-config --cflags)
INCLUDES	:= -I./include
LD		:= gcc
LDFLAGS		:=
PYLDFLAGS	:= -shared -fPIC
LIBS		:= -lm

OBJS		:= $(patsubst %.c,%.o,$(wildcard src/*.c)) src/p.o
EXECS		:= ta_acquisition
PYSOS		:= des.so km.so
PYCS		:= $(patsubst %.py,%.pyc,$(wildcard *.py))
PYOBJS		:= $(patsubst src/%.c,src/PyC_%.o,$(wildcard src/*.c))
DATA		:= ta.dat ta.key

.PHONY: help all clean ultraclean check archive

define HELP_message
Type:
  <make> or <make help> to get this help message
  <make all> to build everything
  <make check> to check the compliance of ta.py and p.c with specifications
  <make archive> to create the archive of your work
  <make clean> to clean a bit
  <make ultraclean> to really clean
endef
export HELP_message

help:
	@echo "$$HELP_message"

all: $(EXECS) $(PYSOS)

ta_acquisition: src/ta_acquisition.o src/des.o src/rdtsc_timer.o src/utils.o src/p.o
	$(LD) $(LDFLAGS) $^ -o $@ $(LIBS)

src/Py_%.o src/PyC_%.o: CFLAGS += $(PYCFLAGS)

src/PyC_%.o: src/%.c
	$(CC) $(CFLAGS) $(OPT) $(INCLUDES) $< -o $@

src/p.o: p.c
	$(CC) $(CFLAGS) -O0 $(INCLUDES) $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) $(OPT) $(INCLUDES) $< -o $@

des.so: src/Py_des.o src/PyC_des.o src/PyC_utils.o
	$(LD) $(PYLDFLAGS) $^ -o $@ $(LIBS)

km.so: src/Py_km.o src/PyC_km.o src/PyC_utils.o src/PyC_des.o
	$(LD) $(PYLDFLAGS) $^ -o $@ $(LIBS)
define NOREPORT_message
Report not found. Please write your report, name it report.txt (plain text
report) or report.pdf (PDF format) and run the script again. Note: if both
formats are found, only the PDF version will be used. Exiting..."
endef
export NOREPORT_message

define NOSTUDENT1_message
Student #1 cannot be undefined. Please edit the team.txt file and specify
at least student1. Exiting...
endef
export NOSTUDENT1_message

define CHECK_message
################################################################################
Please check the following information and, if they are correct, send an
un-signed and un-encrypted e-mail to:
  renaud.pacalet@telecom-paristech.fr
with subject exactly:
  HWSec-TA
and with the generated HWSec-TA.tgz archive attached. The e-mail body and other
attachments will be ignored.
################################################################################
endef
export CHECK_message

archive:
	@MandatoryFilesList="team.txt ta.py p.c" && \
	for f in $$MandatoryFilesList; do \
		if [ ! -f $$f ]; then \
			echo "$$f file not found. Exiting..." && \
			exit -1; \
		fi; \
	done && \
	if [ -f report.pdf ]; then \
		report=report.pdf; \
	elif [ -f report.txt ]; then \
		report=report.txt; \
	else \
		echo "$$NOREPORT_message" && \
		exit -1; \
	fi && \
	. ./team.txt && \
	if [ -z "$$student1" ]; then \
		echo "$$NOSTUDENT1_message" && \
		exit -1; \
	fi && \
	if [ -f HWSec-TA.tgz ]; then \
		echo "HWSec-TA.tgz archive already exists. Rename or delete it first. Exiting..." && \
		exit -1; \
	fi && \
	tar hzcf HWSec-TA.tgz "$$report" $$MandatoryFilesList && \
	echo "$$CHECK_message" && \
	echo "Student #1: $$student1" && \
	if [ -z "$$email1" ]; then \
		echo "Email #1:   none (results will be e-mailed to sender)"; \
	else \
		echo "Email #1:   $$email1"; \
	fi && \
	if [ ! -z "$$student2" ]; then \
		echo "Student #2: $$student2" && \
		if [ -z "$$email2" ]; then \
			echo "Email #2:   none"; \
		else \
			echo "Email #2:   $$email2"; \
		fi; \
	fi && \
	echo "Report:     $$report"

check: .tests/hwsec_ta.tgz .tests/ta.dat ta.py p.c
	@cd .tests/hwsec_ta && \
	cp ../../ta.py . && \
	k=`./ta.py ../ta.dat 10` && \
	if [[ ! "$$k" =~ ^0x[0-9a-fA-F]{12}$$ ]]; then \
		echo "ta.py invalid output:" && \
		echo "$$k" && \
		exit 1; \
	fi && \
	cp ../../p.c . && \
	$(MAKE) ta_acquisition && \
	k=`./ta_acquisition 10` && \
	if [[ ! "$$k" =~ ^0x[0-9a-fA-F]{12}$$ ]]; then \
		echo "p.c invalid output" && \
	        echo "$$k" && \
		exit 1; \
	fi && \
	echo && \
	echo "Check OK. You can now make the archive."

.tests/hwsec_ta.tgz:
	@mkdir -p .tests && \
	cd .tests && \
	rm -f hwsec_ta.tgz && \
	wget http://soc.eurecom.fr/HWSec/labs/python/hwsec_ta.tgz &> /dev/null && \
	rm -rf hwsec_ta && \
	tar xf hwsec_ta.tgz &> /dev/null && \
	$(MAKE) -C hwsec_ta all &> /dev/null

.tests/ta.dat:
	@mkdir -p .tests && \
	cd .tests && \
	rm -f ta.dat && \
	wget http://soc.eurecom.fr/HWSec/labs/ta.dat &> /dev/null

clean:
	rm -f $(OBJS)

ultraclean: clean
	rm -rf $(EXECS) $(DATA) $(PYSOS) $(PYCS) $(PYOBJS) .tests
