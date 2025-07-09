# SETUP PATHS
ROOT=..
DABA=$(ROOT)/daba/daba/
SRC=$(ROOT)/corbama
vpath %.txt $(SRC)
vpath %.html $(SRC)
vpath %.dabased $(SRC)
vpath %.bam-fra.prl $(SRC)
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
PYTHON=PYTHONPATH=$(DABA) python3
PARSER=mparser -s apostrophe
daba2vert=$(PYTHON) $(DABA)/ad-hoc/daba2vert.py -v $(BAMADABA)/bamadaba.txt
#daba2vert=$(PYTHON) $(DABA)/ad-hoc/daba2vert.py -v $(BAMADABA)/bamadaba-disamb-syn.txt
#daba2align=mparser -N -f sentlist
#daba2align=$(PYTHON) $(DABA)/ad-hoc/daba2align.py
daba2align=daba2align
daba2conllu=python scripts/daba2conllu.py
#dabased=$(PYTHON) $(DABA)/dabased.py -v
dabased=dabased -v
REPL=python ../repl/repl.py3
#REPL=../repl/nuitka/repl.bin
#REPL=../repl.dist/repl
repldeps=../repl/repl.py3 ../repl/REPL-STANDARD.txt
RSYNC=rsync -avP --stats -e ssh
gitsrc=git --git-dir=$(SRC)/.git/
makelexicon=$(PYTHON) $(DABA)/ad-hoc/tt-make-lexicon.py
# 
# EXTERNAL RESOURCES
grammar=$(BAMADABA)/bamana.gram.txt
dictionaries := $(addprefix $(BAMADABA)/,bamadaba.txt jamuw.txt togow.txt yorow.txt enciclop.txt ETRGFRA.txt)
#dabafiles := $(addrefix $(DABA),grammar.py formats.py mparser.py newmorph.py)
#dictionaries := $(addprefix $(BAMADABA)/,bamadaba-disamb-syn.txt)
dabafiles := $(addprefix $(DABA),grammar.py formats.py mparser.py newmorph.py)

# 
# SOURCE FILELISTS
gitfiles := $(shell $(gitsrc) ls-files)
auxtxtfiles := freqlist.txt
frafiles := $(filter %.fra.txt, $(gitfiles))
bamtxtfiles := $(filter %.bam.txt, $(gitfiles))
txtfiles := $(filter-out $(auxtxtfiles) $(frafiles) $(bamtxtfiles),$(filter %.txt,$(gitfiles)))
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
prlajuste-fra := $(filter %.fra2.txt,$(gitfiles))
prlajuste-prl := $(patsubst %.fra2.txt,%.bam-fra2.prl,$(prlajuste-fra))
ajustebam := $(patsubst %.fra2.txt,%.non-tonal.vert,$(prlajuste-fra))
ajustefra := $(patsubst %.fra2.txt,%.fra2.vert,$(prlajuste-fra))
alignedbam := $(patsubst %.bam-fra.prl,%.non-tonal.vert,$(prlfiles))
alignedfra := $(patsubst %.bam-fra.prl,%.fra.vert,$(prlfiles))
nonajustebam := $(filter-out $(prlajuste-prl),$(prlfiles:.bam-fra.prl=.bam-fra2.prl))
corbamafara-files := $(alignedbam) $(filter-out $(alignedbam),$(ajustebam))
corfarabama-files := $(alignedfra) $(filter-out $(alignedfra:.fra.vert=.fra2.vert),$(ajustefra))
corfarabama-ajuste-files := $(ajustefra)
corfarabama-prl := $(prlfiles) $(filter-out $(prlfiles:.bam-fra.prl=.bam-fra2.prl),$(prlajuste-prl))
corfarabama-ajuste-prl := $(prlajuste-prl) $(nonajustebam)
#prlfiles-full := $(prlajuste-prl) $(prlfiles)
#prlfiles-ajuste := $(prlajuste-prl) $(patsubst %.bam-fra.prl,%.bam-fra2.prl,$(prlfiles))
#netfiles-fullpath := $(realpath $(patsubst %,$(SRC)/%.html,$(netfiles)))
# Lemmatizer files
tkzfiles := $(addsuffix .tkz,$(basename $(parsefiles) $(parseoldfiles)))
tokenfiles := $(tkzfiles:.tkz=.tokens)
# Parallel files for testing alignment
export bamtxtsources := $(corbamafara-files:.non-tonal.vert=.bam.txt)
export fratxtsources := $(corfarabama-files:.vert=.txt)
export fra2txtsources := $(corfarabama-ajuste-files:.vert=.txt)


## Corpora — main part
corpbasename := corbama
corpsite := corbama
corpora := corbama-net-non-tonal corbama-net-tonal corbama-brut 
corpora-prl := corbamafara corfarabama corfarabama-ajuste
corpora-vert := $(addsuffix .vert, $(corpora))
compiled := $(patsubst %,export/data/%/word.lex,$(corpora))
## Remote corpus installation data
corpsite-corbama := corbama
corpora-corbama := corbama-net-non-tonal corbama-net-tonal corbama-brut
## Parallel subcorpus
corpsite-corbama-prl := corbama
corpora-corbama-prl := corbamafara corfarabama corfarabama-ajuste


include remote.mk
include docker.mk
#include tests.mk


.PRECIOUS: $(parshtmlfiles) $(bamtxtfiles) %.repl.html

.PHONY: %.list

all: compile

print-%:
	@echo $(info $($*))

%.pars.tonal.vert: %.pars.html
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"

%.pars.non-tonal.vert: %.pars.html
	$(daba2vert) "$<" --unique --convert --polisemy > "$@"

%.bam.non-tonal.vert: %.pars.html
	$(daba2vert) "$<" --unique --convert --polisemy > "$@"

%.non-tonal.vert: %.pars.html
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
	$(daba2vert) "$<" --tonal --unique --convert --canonical --senttag "SENT" --conll > "$@"

%.dis.conll: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --convert --canonical --conll --senttag "SENT" | \
	awk -F"\t" -v OFS="\t" '/^<doc/ {print "#" " " $$0; next} /^</ && $$2 != "SENT" {next} {print $$1, $$3, $$2}' > "$@"

%.dis.tonal.conll: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --convert --canonical --conll --senttag "SENT" --tonal | \
	awk -F"\t" -v OFS="\t" '/^<doc/ {print "#" " " $$0; next} /^</ && $$2 != "SENT" {next} {print $$1, $$3, $$2}' > "$@"

%.dis.tonal.conllu: %.dis.html %.dis.dbs
	$(daba2conllu) "$<" > "$@"

%.dis.bam.txt: %.dis.html
	$(daba2align) "$<" "$@"

%.pars.bam.txt: %.ppars.html
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

%.ppars.html: %.bam.txt $(dictionaries) $(grammar) $(dabafiles)
	$(PARSER) -i "$<" -o "$@" --sentlist

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

%.tokens: %.tkz
	cat $< | sed '1a\\n' | gawk 'BEGIN{RS=""} {for (i=1;i<=NF;i++) {printf "%s ", $$i}; printf "\n" }' > $@

%.dis.pars.html: %.dis.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.dis.pars.non-tonal.vert: %.dis.pars.html
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.dis.pars.tonal.vert: %.dis.pars.html 
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"

%.repl.html: %.pars.html $(repldeps)
	$(REPL) "$*"

%.old.repl.html: %.old.pars.html $(repldeps)
	$(REPL) "$*.old"

%.repl.tonal.vert: %.dis.repl.html $(repldeps)
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"

%.repl.non-tonal.vert: %.old.repl.html $(repldeps)
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.repl.non-tonal.vert: %.repl.html $(repldeps)
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.repl.non-tonal.vert: %.dis.pars.html $(repldeps)
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.repl.diff: %.repl.non-tonal.vert %.dis.non-tonal.vert
	diff -u $^ | python scripts/repldiff.py > "$@"

%.fra.vert: %.fra.txt
	python scripts/spacy-lemmatize-fr.py $< $@

%.fra.vert: %.dis.fra.txt
	python scripts/spacy-lemmatize-fr.py $< $@

%.fra2.vert: %.fra2.txt
	python scripts/spacy-lemmatize-fr.py $< $@

%.bam-fra2.prl: %.fra2.txt
	last=$$(sed -n 's,<s n="\([0-9]\+\).*,\1,p' $< | tail -1) ; echo "0:$$last	0:$$last" > $@

%.bam-fra2.prl: %.bam.txt
	last=$$(sed -n 's,<s n="\([0-9]\+\).*,\1,p' $< | tail -1) ; echo "0,$$last	-1" > $@

%.dis.dbs: %.dis.html $(dabasedfiles)
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
	touch $@

all: compile

parse: $(parshtmlfiles)

resources: $(dictionaries) $(grammar) $(dabafiles)
	rm -f run/*
	$(PARSER) -n -g $(grammar) $(addprefix -d ,$(dictionaries))
	touch $@

makedirs:
	find $(SRC) -type d | sed 's,$(SRC)/,,' | fgrep -v .git | xargs -n1 mkdir -p

run.dabased: $(addsuffix .dbs,$(netfiles))

corbama-nul.vert: $(addsuffix .nul.vert,$(brutfiles))
	$(file >$@) $(foreach f,$(sort $^),$(shell cat $f >> $@))
	@true

corbama-brut.vert: $(addsuffix .non-tonal.vert,$(brutfiles))
	$(file >$@) $(foreach f,$(sort $^),$(shell cat $f >> $@))
	@true

corbama-net-tonal.vert: $(addsuffix .tonal.vert,$(netfiles)) 
	$(file >$@) $(foreach f,$(sort $^),$(shell cat $f >> $@))
	@true

corbama-net-non-tonal.vert: $(addsuffix .non-tonal.vert,$(netfiles)) 
	$(file >$@) $(foreach f,$(sort $^),$(shell cat $f >> $@))
	@true

corbama-net-non-tonal.conll: $(addsuffix .conll,$(netfiles)) 
	$(file >$@) $(foreach f,$(sort $^),$(shell cat $f >> $@))
	@true

corbama-net-tonal.conll: $(addsuffix .tonal.conll,$(netfiles)) 
	$(file >$@) $(foreach O,$(sort $^),$(file >>$@,$(file <$O)))
	@true

corbama-net-tonal.lemma.vert: $(addsuffix .lemma.vert,$(netfiles)) 
	cat $(sort $^) > $@

corbama-net-tonal.conllu: $(addsuffix .tonal.conllu,$(netfiles)) 
	cat $(sort $^) > $@

corbama-brut.tokenized: $(tokenfiles)
	$(file >$@) $(foreach O,$(sort $^),$(file >>$@,$(file <$O)))

corbamafara.vert: $(corbamafara-files)
	$(file >$@) $(foreach O,$(sort $^),$(file >>$@,$(file <$O)))
	sed -i '/<s>/N;s,<s>\s*\n</s>,<s>\n.\t.\t.\t.\t.\t.\t.\t.\t.\n</s>,' $@
	@true

corfarabama.vert: $(corfarabama-files)
	$(file >$@) $(foreach O,$(sort $^),$(file >>$@,$(file <$O)))
	sed -i '/^<s /N;s,^<s\([^>]\+>\)\s*\n</s>,<s\1\n.\t.\t.\t.\t.\n</s>,' $@
	@true

corfarabama-ajuste.vert: $(corfarabama-ajuste-files)
	$(file >$@) $(foreach O,$(sort $^),$(file >>$@,$(file <$O)))
	sed -i '/^<s /N;s,^<s\([^>]\+>\)\s*\n</s>,<s\1\n.\t.\t.\t.\t.\n</s>,' $@
	@true

corbama-bam-fra.prl: $(corfarabama-prl)
	python scripts/catprl.py $(patsubst %.bam-fra.prl,$(SRC)/%.bam-fra.prl,$(sort $(corfarabama-prl))) > $@

corbama-fra-bam.prl: corbama-bam-fra.prl
	awk 'BEGIN{FS="\t";OFS="\t"}{print $$2, $$1}' $< > $@

corbama-bam-fra2.prl: $(corfarabama-ajuste-prl)
	python scripts/catprl.py $(sort $^) > $@

corbama-fra2-bam.prl: corbama-bam-fra2.prl
	awk 'BEGIN{FS="\t";OFS="\t"}{print $$2, $$1}' $< > $@

compile: $(corpora-vert)

compile-prl: corbamafara.vert corfarabama.vert corfarabama-ajuste.vert corbama-bam-fra.prl corbama-fra-bam.prl corbama-bam-fra2.prl corbama-fra2-bam.prl

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
	sed -i 's,./export,/var/lib/manatee/,' export/registry/$*

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
	sed -i '/^\s*<doc/d' $?
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

test: $(bamtxtfiles)
	$(MAKE) -C tests

test-parallel: $(bamtxtsources) $(fratxtsources) $(fra2txtsources) corbamafara.vert corfarabama.vert corfarabama-ajuste.vert corbama-bam-fra.prl corbama-bam-fra2.prl 
	$(MAKE) -C tests 


net-subparts:
	for type in text_medium source_type ; do \
	for suffix in non-tonal tonal ; do \
	rm -vf corbama-net-$$suffix-$$type-*.vert ; \
	for file in $(addsuffix .$$suffix.vert,$(netfiles)) ; do \
	cat $$file >> "corbama-net-$$suffix-$$type-$$(sed -n 's/.*'$$type'="\([^"]\+\)".*/\L\1/p' $$file | sed 's/ /_/g' | grep . || echo "undef").vert" ; \
	done ; done ; done
