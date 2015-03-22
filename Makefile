# SETUP PATHS
ROOT=..
DABA=$(ROOT)/daba/
SRC=$(ROOT)/corbama
vpath %.txt $(SRC)
vpath %.html $(SRC)
vpath %.dabased $(SRC)
#
# UTILS
BAMADABA=$(ROOT)/bamadaba
PYTHON=PYTHONPATH=$(DABA) python
PARSER=$(PYTHON) $(DABA)/mparser.py -s apostrophe 
daba2vert=$(PYTHON) $(DABA)/ad-hoc/daba2vert.py -v $(BAMADABA)/bamadaba.txt
dabased=$(PYTHON) $(DABA)/dabased.py
# 
# EXTERNAL RESOURCES
grammar=$(DABA)/doc/samples/bamana.gram.txt
dictionaries := $(addprefix $(BAMADABA)/,bamadaba.txt jamuw.txt togow.txt yorow.txt enciclop.txt)
dabafiles := $(addrefix $(DABA),grammar.py formats.py mparser.py newmorph.py)
# 
# SOURCE FILELISTS
auxtxtfiles := freqlist.txt
dishtmlfiles := $(patsubst $(SRC)/%,%,$(wildcard $(SRC)/*.dis.html $(SRC)/*/*.dis.html $(SRC)/*/*/*.dis.html))
htmlfiles := $(filter-out %.pars.html %.dis.html,$(patsubst $(SRC)/%,%,$(wildcard $(SRC)/*.html $(SRC)/*/*.html $(SRC)/*/*/*.html)))
txtfiles := $(patsubst $(SRC)/%,%,$(wildcard $(SRC)/*.txt $(SRC)/*/*.txt $(SRC)/*/*/*.txt))
srctxtfiles := $(filter-out $(htmlfiles:.html=.txt) $(dishtmlfiles:.dis.html=.txt) $(dishtmlfiles:.dis.html=.old.txt) $(auxtxtfiles) %_fra.txt,$(txtfiles))
srchtmlfiles := $(filter-out $(dishtmlfiles:.dis.html=.html) $(dishtmlfiles:.dis.html=.old.html),$(htmlfiles))
parsefiles := $(filter-out %.old.html,$(srchtmlfiles)) $(filter-out %.old.txt,$(srctxtfiles))
parseoldfiles := $(filter %.old.html,$(srchtmlfiles)) $(filter %.old.txt,$(srctxtfiles))
dabasedfiles := $(wildcard releases/*/*.dabased)
parshtmlfiles := $(addsuffix .pars.html,$(basename $(parsefiles) $(parseoldfiles)))
netfiles := $(patsubst %.html,%,$(dishtmlfiles))
brutfiles := $(netfiles) $(patsubst %.html,%,$(parshtmlfiles))

corpora := corbama-nul corbama-brut corbama-net-tonal corbama-net-non-tonal
corpora-vert := $(addsuffix .vert, $(corpora))

.PRECIOUS: $(parshtmlfiles)

test:
	#@echo $(brutfiles) | tr ' ' '\n'
	@echo $(srctxtfiles) | tr ' ' '\n'

%.pars.tonal.vert: %.pars.html
	$(daba2vert) "$<" --tonel --unique --convert --polisemy > "$@"
	
%.pars.non-tonal.vert: %.pars.html
	$(daba2vert) "$<" --unique --convert --polisemy > "$@"

%.dis.tonal.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"
	
%.dis.non-tonal.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.nul.vert: %.html
	$(daba2vert) "$<" -u -n -c > "$@"

%.vert: config/%
	mkdir -p export/$*/data
	encodevert -c ./$< -p export/$*/data $@ 

%.old.pars.html: %.old.html
	$(PARSER) -s bamlatinold -i "$<" -o "$@"

%.old.pars.html: %.old.txt
	$(PARSER) -s bamlatinold -i "$<" -o "$@"

%.pars.html: %.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.pars.html: %.txt $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.dis.dbs: %.dis.html $(dabasedfiles)
	for f in $(dabasedfiles); do $(dabased) -s $$f $< ; done && touch $@

all: compile

resources: $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -n -g $(grammar) $(addprefix -d ,$(dictionaries))

corbama-nul.vert: $(addsuffix .nul.vert,$(brutfiles))
	rm -f $@
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@ ; done

corbama-brut.vert: $(addsuffix .non-tonal.vert,$(brutfiles))
	rm -f $@
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@ ; done
	
corbama-net-tonal.vert: $(addsuffix .tonal.vert,$(netfiles)) $(addsuffix .dbs,$(netfiles))
	cat $(sort $^) > $@
	
corbama-net-non-tonal.vert: $(addsuffix .non-tonal.vert,$(netfiles)) $(addsuffix .dbs,$(netfiles))
	cat $(sort $^) > $@

compile: $(corpora-vert)

freqlist.txt: corbama-net-tonal.vert
	python $(SRC)/freqlist.py $< > $@

export/data/%/word.lex: config/% %.vert
	mkdir -p $(@D)
	mkdir -p export/registry
	mkdir -p export/vert
	encodevert -c ./$< -p $(@D) $*.vert
	cp $< export/registry
	cp $*.vert export/vert

corbama-dist.zip:
	git archive -o corbama-dist.zip --format=zip HEAD

corbama-dist.tar.xz:
	git archive --format=tar HEAD | xz -c > corbama-dist.tar.xz

dist-zip: corbama-dist.zip

dist: $(foreach corpus,$(corpora),export/data/$(corpus)/word.lex)
	echo $@	

dist-print:
	echo $(foreach corpus,$(corpora),export/data/$(corpus)/word.lex)

export/corbama.tar.xz: dist
	pushd export ; tar cJvf corbama.tar.xz * ; popd

install: export/corbama.tar.xz
	rsync -avP --stats $< root@maslinsky:/var/lib/manatee/
	ssh root@maslinsky rm -rf /var/lib/manatee/{data,registry,vert}/corbama*
	ssh root@maslinsky "cd /var/lib/manatee && tar xJvf corbama.tar.xz"

install-local: export/corbama.tar.xz
	rm -rf /var/lib/manatee/{data,registry,vert}/corbama*
	cd /var/lib/manatee && tar xJvf $<


corpsize:
	@echo "net:" `awk 'NF>1 && $$1 !~ /^</ && $$3 != "c" {print}' corbama-net-non-tonal.vert | wc -l`
	@echo "brut:" `awk 'NF>1 && $$1 !~ /^</ && $$3 != "c" {print}' corbama-brut.vert | wc -l`
#	find -name \*.dis.html -print0 | xargs -0 -n 1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "net:" c}'
#	find -name \*.pars.html -print0 | xargs -0 -n 1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "brut:" c}'

clean: clean-vert clean-parse clean-pars

clean-vert:
	find -name \*.vert -not -name corbama-\*.vert -exec rm -f {} \;
	rm -f run/.vertical

clean-parse: 
	rm -f parse.filelist parseold.filelist run/status

clean-dabased:
	rm -f run/.dabased

clean-duplicates:
	git ls-files \*.dis.html | while read i ; do test -f $${i%%.dis.html}.pars.html && git rm -f $${i%%.dis.html}.pars.html ; done

clean-pars:
	find -name \*.pars.html -exec rm -f {} \;

makedirs:
	find $(SRC) -type d | sed 's,$(SRC)/,,' | fgrep -v .git | xargs -n1 mkdir -p
