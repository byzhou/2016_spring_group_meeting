# Configuration for latex-base.
#
# Contact point: Schuyler Eldridge <schuyler.eldridge@gmail.com>

# Set the values of PAPER and PRESENTATION correctly below to the
# names of your top-level LaTeX paper and presentation files. For
# example, if your top-level paper .tex is "paper.tex" and your
# presentation is "presentation.tex" the defines below should be
# changed to:
#   define(PAPER, paper)
#   define(PRESENTATION, presentation)

# The name of the top-level LaTeX paper file

# The name of the top-level LaTeX presentation file

# The name of the top-level LaTeX poster file

# latexmk-driven build flow
#
# Point of Contact: Schuyler Eldridge <schuyler.eldridge@gmail.com>

#--------------------------------------- Configuration user should modify
# Each one of these needs a set of explicit build rules below. I can't
# use pattern rules because GNU Make doesn't allow for PHONY pattern
# rules. More detail below.
SOURCES_TEX = latex-base.tex latex-base-presentation.tex latex-base-poster.tex

#--------------------------------------- Configuration that _should_ be static
DIR_BUILD   = build
DIR_SRC     = src
DIR_BAK     = $(DIR_SRC)/bak
DIR_CB      = submodules/palette-art
DIR_TEX     = $(DIR_SRC) \
	$(DIR_SRC)/figures \
	$(DIR_SRC)/templates \
	$(DIR_CB)/latex
DIR_BIB     = . ../ ../src/bib build
DIR_SCRIPTS = scripts

SUPPORT_TEX = $(DIR_CB)/latex/colorbrewer.tex
TARGETS_PDF = $(SOURCES_TEX:%.tex=$(DIR_BUILD)/%.pdf)
TARGETS_PS  = $(SOURCES_TEX:%.tex=$(DIR_BUILD)/%.ps)
TARGETS_OPT = $(TARGETS_PDF:%.pdf=%-opt.pdf)

SPACE       = $(EMPTY) $(EMPTY)

LATEXMK_PDF = ~/colorlatexmk \
	-pdf \
	-latexoption="--shell-escape -halt-on-error -file-line-error" \
	-bibtex \
	-time \
	-outdir=$(DIR_BUILD)
LATEXMK_PS  = latexmk \
	-ps \
	-latexoption="--shell-escape -halt-on-error -file-line-error" \
	-bibtex \
	-time \
	-outdir=$(DIR_BUILD)
GS_OPT      = gs \
	-sDEVICE=pdfwrite \
	-dNOPAUSE \
	-dBATCH
ENV         = env TEXINPUTS="$(TEXINPUTS)$(subst $(SPACE),:,$(DIR_TEX)):" \
	BIBINPUTS="$(BIBINPUTS)$(subst $(SPACE),:,$(DIR_BIB)):"

vpath %.tex src

.PHONY: all clean format format-build noformat-build ps optimized \
	$(TARGETS_PDF) $(TARGETS_PS) $(TARGETS_OPT)

# Default target. This should either be set to build all targets with
# LaTeX formatting cleanup (format-build) OR to just build without
# cleanup (noformat-build)
all: noformat-build

# pdf viewer
view:
	@if which mupdf > /dev/null; then\
		mupdf -r 250 build/latex-base-presentation.pdf &\
	else\
		evince build/latex-base-presentation.pdf &\
	fi

# Top-level build target that runs format (cleanup all source files
# into a "nice" format good for version control) before building
format-build: format noformat-build
	@echo "  ########################################"
	@echo "  # WARNING"
	@echo "  ########################################"
	@echo "  # You just ran a \`format-build\` which converts source files"
	@echo "  # to one-sentence-per-line format. Copies of the _most recent_"
	@echo "  # originals were save in *.bak"
	@echo "  ########################################"

# Top-level build target that will build all targets without source
# file cleanup
noformat-build: $(TARGETS_PDF)

# Top-level build target that generates optimized versions of the
# pdfs using GhostScript.
optimized: $(TARGETS_OPT)

# Source file cleanup using fmtlatex. This looks for all .tex files
# that start with 'sec-' in the source directory (files in
# subdirectories of src are ignored, e.g., figures) and pushes them
# throgh fmtlatex which will convert them to a one sentence per line
# structure. Backups _of_the_most_recent_version_ONLY_ are made with a
# .bak suffix.
format:
	find src -maxdepth 1 -regex ^.*?sec-.+?\.tex | sed "s/src\///" |\
	xargs -I TEX sh -c \
	'cp $(DIR_SRC)/TEX $(DIR_BAK)/TEX.bak && $(DIR_SCRIPTS)/fmtlatex -n 2 $(DIR_BAK)/TEX.bak > $(DIR_SRC)/TEX'

# Postscript target. This is currently NOT WORKING.
ps: $(TARGETS_PS)

# Regenerate the Makefile if anything has changed with the
# configuration
Makefile: Makefile.in CONFIG.m4
	m4 CONFIG.m4 Makefile.in > Makefile

# I use explicit build rules for the paper and presentation because I
# need these rules to be run everytime, i.e., "PHONY" rules, but GNU
# Make doesn't allow you to have PHONY pattern rules. These rules must
# be run everytime because GNU Make has no concept of the dependencies
# within the LaTeX files and we need to rely on latexmk to figure all
# this out. So... this is a bit of an ugly kludge that doesn't scale
# if you start having tons of targets. [TODO] Figure out a way to do
# this better.

# Paper build rules
$(DIR_BUILD)/latex-base.pdf:latex-base.tex $(SUPPORT_TEX) Makefile
	$(ENV) $(LATEXMK_PDF) $<
$(DIR_BUILD)/latex-base.ps:latex-base.tex $(SUPPORT_TEX) Makefile
	$(ENV) $(LATEXMK_PS) $<
$(DIR_BUILD)/paper-opt.pdf:$(DIR_BUILD)/latex-base.pdf
	$(GS_OPT) -sOutputFile=$@ $<

# Presentation build rules
$(DIR_BUILD)/latex-base-presentation.pdf:latex-base-presentation.tex $(SUPPORT_TEX) Makefile
	$(ENV) $(LATEXMK_PDF) $<
$(DIR_BUILD)/latex-base-presentation.ps:latex-base-presentation.tex $(SUPPORT_TEX) Makefile
	$(ENV) $(LATEXMK_PS) $<
$(DIR_BUILD)/latex-base-presentation-opt.pdf:$(DIR_BUILD)/latex-base-presentation.pdf
	$(GS_OPT) -sOutputFile=$@ $<

# Poster build rules
$(DIR_BUILD)/latex-base-poster.pdf:latex-base-poster.tex $(SUPPORT_TEX) Makefile
	$(ENV) $(LATEXMK_PDF) $<
$(DIR_BUILD)/latex-base-poster.ps:latex-base-poster.tex $(SUPPORT_TEX) Makefile
	$(ENV) $(LATEXMK_PS) $<
$(DIR_BUILD)/latex-base-poster-opt.pdf:$(DIR_BUILD)/latex-base-poster.pdf
	$(GS_OPT) -sOutputFile=$@ $<

# Untested target that embeds fonts. To check for embedded fonts, I
# can use the following bash one-liner:
#   if [[ -n `pdffonts 2014_delaware.pdf | tail -n +3 | awk '{print $5}' | grep no` ]]; then echo "Unembedded"; fi
$(DIR_BUILD)/%-embed.pdf: $(DIR_BUILD)/%.pdf
	gs \
		-dBATCH \
		-dNOPAUSE \
		-sDEVICE=pdfwrite \
		-sOutputFile=$@  \
		-dPDFSETTINGS=/prepress \
		-dEmbedAllFonts=true \
		-dSubsetFonts=true \
		-dCompatibilityLevel=1.6 $<

clean:
	rm -f $(DIR_BUILD)/* \
	*.dpth \
	*.pdf \
	*.log \
	*.vrb \
	*.aux \
	*.fdb_latexmk \
	*.dep \
	*.fls

#--------------------------------------- Colorbrewer Submodule Setup
# Target to generate colorbrewer.tex in the palette-art submodule
# directory
$(DIR_CB)/latex/colorbrewer.tex: $(DIR_CB)/latex/colorbrewer.pl
	make -C $(DIR_CB)/latex

# If the colorbrewer generating perl script doesn't exist, then we
# haven't initialized the git submodule. This target takes care of
# this.
$(DIR_CB)/latex/colorbrewer.pl:
	git submodule init
	git submodule update