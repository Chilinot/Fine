default: compile clean

OUTPUTNAME=Compiler_Design_Project_\(2016\)_-_Intermediate_Representation_and_Code_Generation
MAINFILE=main.tex

# We need to compile the document twice for biber to work, since it relies on the generated output
compile:
	cat $(MAINFILE) | pdflatex -jobname=$(OUTPUTNAME)
	#biber $(OUTPUTNAME)
	cat $(MAINFILE) | pdflatex -jobname=$(OUTPUTNAME)
.PHONY: compile

# Remove all auto generated files
clean:
	rm *.out *.aux *.bbl *.bcf *.blg *.log *.run.xml
.PHONY: clean
