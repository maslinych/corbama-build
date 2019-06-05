# SETUP PATHS
ROOT=..
DABA=$(ROOT)/daba/daba/
SRC=$(ROOT)/corbama
vpath %.txt $(SRC)
vpath %.html $(SRC)
vpath %.dabased $(SRC)
vpath %.prl $(SRC)
#
# SETUP CREDENTIALS
HOST=corpora
# CHROOTS
TESTING=testing
PRODUCTION=production
ROLLBACK=rollback
TESTPORT=8098
PRODPORT=8099
BUILT=built
# UTILS
BAMADABA=$(ROOT)/bamadaba
PYTHON=PYTHONPATH=$(DABA) python
PARSER=mparser -s apostrophe
#daba2vert=$(PYTHON) $(DABA)/ad-hoc/daba2vert.py -v $(BAMADABA)/bamadaba.txt
daba2vert=$(PYTHON) $(DABA)/ad-hoc/daba2vert.py -v $(BAMADABA)/bamadaba-disamb-syn.txt
#daba2align=mparser -N -f sentlist
#daba2align=$(PYTHON) $(DABA)/ad-hoc/daba2align.py
daba2align=daba2align
#dabased=$(PYTHON) $(DABA)/dabased.py -v
dabased=dabased -v
REPL=python ../repl/repl.py
RSYNC=rsync -avP --stats -e ssh
gitsrc=git --git-dir=$(SRC)/.git/
makelexicon=$(PYTHON) $(DABA)/ad-hoc/tt-make-lexicon.py
# 
# EXTERNAL RESOURCES
grammar=$(BAMADABA)/bamana.gram.txt
#dictionaries := $(addprefix $(BAMADABA)/,bamadaba.txt jamuw.txt togow.txt yorow.txt enciclop.txt ETRGFRA.txt)
#dabafiles := $(addrefix $(DABA),grammar.py formats.py mparser.py newmorph.py)
dictionaries := $(addprefix $(BAMADABA)/,bamadaba-disamb-syn.txt)
dabafiles := $(addprefix $(DABA),grammar.py formats.py mparser.py newmorph.py)

# 
# SOURCE FILELISTS
gitfiles := $(shell $(gitsrc) ls-files)
auxtxtfiles := freqlist.txt
frafiles := $(filter %.fra.txt, $(gitfiles))
txtfiles := $(filter-out $(auxtxtfiles) $(frafiles),$(filter %.txt,$(gitfiles)))
htmlfiles := $(filter-out %.pars.html %.dis.html,$(filter %.html,$(gitfiles)))
dishtmlfiles := $(filter %.dis.html,$(gitfiles))
srchtmlfiles := $(filter-out $(dishtmlfiles:.dis.html=.html) $(dishtmlfiles:.dis.html=.old.html),$(htmlfiles))
srctxtfiles := $(filter-out $(htmlfiles:.html=.txt) $(dishtmlfiles:.dis.html=.txt) $(dishtmlfiles:.dis.html=.old.txt) %_fra.txt,$(txtfiles))
parsefiles := $(filter-out %.old.html,$(srchtmlfiles)) $(filter-out %.old.txt,$(srctxtfiles))
parseoldfiles := $(filter %.old.html,$(srchtmlfiles)) $(filter %.old.txt,$(srctxtfiles))
dabasedfiles := $(sort $(wildcard releases/*/*.dabased))
parshtmlfiles := $(addsuffix .pars.html,$(basename $(parsefiles) $(parseoldfiles)))
replfiles := $(patsubst %.pars.html,%.repl.html,$(parshtmlfiles))
netfiles := $(patsubst %.html,%,$(dishtmlfiles))
brutfiles := $(netfiles) $(patsubst %.html,%,$(replfiles))
# Parallel corpus
prlfiles := $(filter %.bam-fra.prl,$(gitfiles))
alignedbam = $(patsubst %.bam-fra.prl,%.non-tonal.vert,$(prlfiles))
alignedfra = $(patsubst %.bam-fra.prl,%.fra.vert,$(prlfiles))
netfiles-fullpath := $(realpath $(patsubst %,$(SRC)/%.html,$(netfiles)))
# Lemmatizer files
tkzfiles := $(addsuffix .tkz,$(basename $(parsefiles) $(parseoldfiles)))


## Corpora — main part
corpbasename := corbama
corpsite := corbama
corpora := corbama-net-non-tonal corbama-net-tonal corbama-brut 
corpora-vert := $(addsuffix .vert, $(corpora))
compiled := $(patsubst %,export/data/%/word.lex,$(corpora))
## Remote corpus installation data
corpsite-corbama := corbama
corpora-corbama := corbama-net-non-tonal corbama-net-tonal corbama-brut
## Parallel subcorpus
corpsite-corbama-prl := corbama
corpora-corbama-prl := corbamafara corfarabama


include remote.mk
include tests.mk


.PRECIOUS: $(parshtmlfiles) %.repl.html

.PHONY: %.list

all: compile

print-%:
	@echo $(info $($*))

%.pars.tonal.vert: %.pars.html
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"

%.pars.non-tonal.vert: %.pars.html
	$(daba2vert) "$<" --unique --convert --polisemy > "$@"

%.pars.nul.vert: %.pars.html
	$(daba2vert) "$<" --unique --null --convert > "$@"

%.dis.tonal.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"

%.dis.non-tonal.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.dis.nul.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --null --convert > "$@"


%.dis.lemma.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --convert --canonical --conll --senttag "SENT" > "$@"

%.dis.conll: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --convert --canonical --conll --senttag "SENT" | \
	awk -F"\t" -v OFS="\t" '/^<doc/ {print "#" " " $$0; next} /^</ && $$2 != "SENT" {next} {print $$1, $$3, $$2}' > "$@"

%.dis.tonal.conll: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --convert --canonical --conll --senttag "SENT" --tonal | \
	awk -F"\t" -v OFS="\t" '/^<doc/ {print "#" " " $$0; next} /^</ && $$2 != "SENT" {next} {print $$1, $$3, $$2}' > "$@"

%.dis.bam.txt: %.dis.html
	$(daba2align) "$<" "$@"

%.pars.bam.txt: %.pars.html
	$(daba2align) "$<" "$@"

%.vert: config/%
	mkdir -p export/$*/data
	encodevert -c ./$< -p export/$*/data $@ 

%.old.pars.html: %.old.html $(dictionaries) $(grammar) $(dabafiles)
	$(PARSER) -s bamlatinold -i "$<" -o "$@"

%.old.pars.html: %.old.txt $(dictionaries) $(grammar) $(dabafiles)
	$(PARSER) -s bamlatinold -i "$<" -o "$@"

%.pars.html: %.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.pars.html: %.txt $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.old.tkz: %.old.txt
	$(PARSER) -N -s bamlatinold -c -f "tokens" -i "$<" -o "$@"

%.tkz: %.txt
	$(PARSER) -N -c -f "tokens" -i "$<" -o "$@"

%.tkz: %.html
	$(PARSER) -N -c -f "tokens" -i "$<" -o "$@"

%.tkzid: %.tkz
	cat $< | awk '$$0 ~ /^# <doc/ {match($$0, /^# <doc path=([^ >]+).tkz/, doc); docid=doc[1]; sentid=1; next} !length($$0) {sentid += 1; next} $$1 ~ /^[#<]/ || NF > 1 {next} NF == 1 {print docid, sentid, $$1}' > $@

%.tkzid: %.conll
	cat $< | awk -F"\t" '$$0 ~ /^# <doc/ {match($$0, /id="([^" >]+).dis.html/, doc); docid=doc[1]; sentid=1; next} $2 == "SENT" {sentid += 1; next} $1 ~ /^</ || NF > 1 {next} NF == 1 {print docid, sentid, $$1}' > $@

%.old.tkz: %.old.html
	$(PARSER) -N -s bamlatinold -c -f "tokens" -i "$<" -o "$@"

%.dis.pars.html: %.dis.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.dis.pars.non-tonal.vert: %.dis.pars.html
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.dis.pars.tonal.vert: %.dis.pars.html 
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"

%.repl.html: %.pars.html
	$(REPL) "$*"

%.old.repl.html: %.old.pars.html
	$(REPL) "$*.old"

%.repl.tonal.vert: %.dis.repl.html
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"

%.repl.non-tonal.vert: %.old.repl.html
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.repl.non-tonal.vert: %.repl.html
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.repl.non-tonal.vert: %.dis.pars.html
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.repl.diff: %.repl.non-tonal.vert %.dis.non-tonal.vert
	diff -u $^ | python scripts/repldiff.py > "$@"

%.fra.vert: %.fra.txt
	cat $< | scripts/melt_it.sh > $@

%.dis.dbs: %.dis.html $(dabasedfiles)
	touch $@
	export lastcommit=$$($(gitsrc) log -n1 --pretty="%H" -- "$(<:$(SRC)/%=%)") ; \
	for f in $(dabasedfiles); do \
		export dabasedsha=$$(sha1sum $$f | cut -f1 -d" ") ; \
		export applyed=$$(cat $@ | while read script scriptsha commitsha ; do \
			if [ $$dabasedsha = $$scriptsha ] ; then \
				if $$($(gitsrc) merge-base --is-ancestor $$commitsha $$lastcommit) ; then \
					echo -n "yes" ; break ;\
				else \
					echo -n "" ; break ;\
				fi ;\
			fi ;\
			done );\
		echo "Already applied:" $< $$f ;\
		test -z "$$applyed" && $(dabased) -s $$f $< && echo $$f $$dabasedsha $$lastcommit >> $@ ;\
		done ; exit 0 

all: compile

parse: $(parshtmlfiles)

resources: $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -n -g $(grammar) $(addprefix -d ,$(dictionaries))
	touch $@

makedirs:
	find $(SRC) -type d | sed 's,$(SRC)/,,' | fgrep -v .git | xargs -n1 mkdir -p

run.dabased: $(addsuffix .dbs,$(netfiles))

corbama-nul.vert: $(addsuffix .nul.vert,$(brutfiles))
	rm -f $@
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@ ; done

corbama-brut.vert: $(addsuffix .non-tonal.vert,$(brutfiles))
	rm -f $@
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@ ; done

corbama-net-tonal.vert: $(addsuffix .tonal.vert,$(netfiles)) 
	cat $(sort $^) > $@

corbama-net-non-tonal.vert: $(addsuffix .non-tonal.vert,$(netfiles)) 
	cat $(sort $^) > $@

corbama-net-non-tonal.conll: $(addsuffix .conll,$(netfiles)) 
	cat $(sort $^) > $@

corbama-net-tonal.conll: $(addsuffix .tonal.conll,$(netfiles)) 
	cat $(sort $^) > $@

corbama-brut.tkz: $(tkzfiles)
	$(file >$@) $(foreach O,$(sort $^),$(file >>$@,$(file <$O)))

corbamafara.vert: $(alignedbam)
	cat $(sort $^) > $@

corfarabama.vert: $(alignedfra)
	rm -f $@
	$(foreach f,$^,echo '<doc id="$(notdir $(f))">' >> $@ ; cat $(f) >> $@ ; echo "</doc>" >> $@ ;) 

corbama-bam-fra.prl: $(prlfiles)
	python scripts/catprl.py $(sort $(prlfiles:%=$(SRC)/%)) > $@

corbama-fra-bam.prl: corbama-bam-fra.prl
	awk 'BEGIN{FS="\t";OFS="\t"}{print $$2, $$1}' corbama-bam-fra.prl > $@

compile: $(corpora-vert)

compile-prl: corbamafara.vert corfarabama.vert corbama-bam-fra.prl corbama-fra-bam.prl $(corpora-corbama-prl:%=export/data/%/word.lex) mkalign

reparse-net: $(addsuffix .pars.html,$(netfiles))

reparse-net-vert: $(addsuffix .pars.non-tonal.vert,$(netfiles)) $(addsuffix .pars.tonal.vert,$(netfiles))

repl: $(replfiles)

repldiff: $(patsubst %.dis.html,%.repl.diff,$(dishtmlfiles))

freqlist.txt: corbama-net-tonal.vert
	python freqlist.py $< > $@

export/data/%/word.lex: config/% %.vert
	rm -rf export/data/$*
	rm -f export/registry/$*
	mkdir -p $(@D)
	mkdir -p export/registry
	mkdir -p export/vert
	encodevert -c ./$< -p $(@D) $*.vert
	cp $< export/registry

corbama-dist.zip:
	git archive -o corbama-dist.zip --format=zip HEAD

corbama-dist.tar.xz:
	git archive --format=tar HEAD | xz -c > corbama-dist.tar.xz

dist-zip: corbama-dist.zip

dist: $(compiled)
	echo $<	

dist-print:
	echo $(foreach corpus,$(corpora),export/data/$(corpus)/word.lex)

export/corbama.tar.xz: $(compiled)
	bash -c "pushd export ; tar cJvf corbama.tar.xz --mode='a+r' * ; popd"

mkalign: corbama-bam-fra.prl corbama-fra-bam.prl
	mkalign corbama-bam-fra.prl export/data/corbamafara/align.corfarabama
	mkalign corbama-fra-bam.prl export/data/corfarabama/align.corbamafara

export/corbama-prl.tar.xz: $(corbama-prl-corpora:%=export/data/%/word.lex) mkalign
	bash -c "pushd export ; tar cJvf corbama-prl.tar.xz --mode='a+r' ./{data,registry}/{corbamafara,corfarabama}/ ; popd"

install-testing: install-corpus-corbama

install-local: export/corbama.tar.xz
	sudo rm -rf /var/lib/manatee/{data,registry,vert}/corbama*
	sudo tar -xJvf $< --directory /var/lib/manatee --no-same-permissions --no-same-owner

install-local-prl: export/corbama-prl.tar.xz
	sudo rm -rf /var/lib/manatee/{data,registry,vert}/{corbamafara,corfarabama}*
	sudo tar -xJvf $< --directory /var/lib/manatee --no-same-permissions --no-same-owner

corpsize:
	@echo "net:" `awk 'NF>1 && $$1 !~ /^</ && $$3 != "c" {print}' corbama-net-non-tonal.vert | wc -l`
	@echo "brut:" `awk 'NF>1 && $$1 !~ /^</ && $$3 != "c" {print}' corbama-brut.vert | wc -l`

corpsize-daba:
	@echo $(brutfiles) | tr ' ' '\n' | fgrep -v .dis | sed 's/.pars/.pars.html/' | xargs -n1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "brut:" c}'
#find -name \*.pars.html -print0 | xargs -0 -n 1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "brut:" c}'


%.list:
	$(foreach brutfile,$($*),$(file >> $@,$(brutfile))) 

%.lexicon.txt: %.list
	$(makelexicon) --corpus . --filelist $< > $@

lexicon.brut.txt: parshtmlfiles.list
	$(makelexicon) --corpus . --runtimedir ./run --join --filelist $< > $@

lexicon.net-tonal.txt: dishtmlfiles.list
	$(makelexicon) --corpus $(SRC) --filelist $< --join > $@

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


net-subparts:
	for type in text_medium source_type ; do \
	for suffix in non-tonal tonal ; do \
	rm -vf corbama-net-$$suffix-$$type-*.vert ; \
	for file in $(addsuffix .$$suffix.vert,$(netfiles)) ; do \
	cat $$file >> "corbama-net-$$suffix-$$type-$$(sed -n 's/.*'$$type'="\([^"]\+\)".*/\L\1/p' $$file | sed 's/ /_/g' | grep . || echo "undef").vert" ; \
	done ; done ; done
