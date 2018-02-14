# SETUP PATHS
ROOT=..
DABA=$(ROOT)/daba/daba/
SRC=$(ROOT)/corbama
vpath %.txt $(SRC)
vpath %.html $(SRC)
vpath %.dabased $(SRC)
#
# SETUP CREDENTIALS
HOST=corpora
# CHROOTS
TESTING=testing
PRODUCTION=production
ROLLBACK=rollback
TESTPORT=8098
PRODPORT=8099
# UTILS
BAMADABA=$(ROOT)/bamadaba
PYTHON=PYTHONPATH=$(DABA) python
PARSER=mparser -s apostrophe
daba2vert=$(PYTHON) $(DABA)/ad-hoc/daba2vert.py -v $(BAMADABA)/bamadaba.txt
daba2align=$(PYTHON) $(DABA)/ad-hoc/daba2align.py
dabased=$(PYTHON) $(DABA)/dabased.py -v
REPL=python ../repl/repl.py
RSYNC=rsync -avP --stats -e ssh
gitsrc=git --git-dir=$(SRC)/.git/
# 
# EXTERNAL RESOURCES
grammar=$(BAMADABA)/bamana.gram.txt
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
dabasedfiles := $(sort $(wildcard releases/*/*.dabased))
parshtmlfiles := $(addsuffix .pars.html,$(basename $(parsefiles) $(parseoldfiles)))
netfiles := $(patsubst %.html,%,$(dishtmlfiles))
brutfiles := $(netfiles) $(patsubst %.html,%,$(parshtmlfiles))
replfiles := $(patsubst %.pars.html,%.repl.html,$(parshtmlfiles))

alignedfiles := $(wildcard *.align.txt */*.align.txt */*/*.align.txt)
bamaligned = $(patsubst %.align.txt,%.non-tonal.vert,$(alignedfiles))


corpora := corbama-net-non-tonal corbama-net-tonal corbama-brut
corpora-vert := $(addsuffix .vert, $(corpora))
compiled := $(patsubst %,export/data/%/word.lex,$(corpora))

.PRECIOUS: $(parshtmlfiles) %.repl.html

test:
	@echo $(brutfiles) | tr ' ' '\n'

print-%:
	$(info $*=$($*))

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

%.dis.align.txt: %.dis.html
	$(daba2align) "$<" "$@"

%.pars.align.txt: %.pars.html
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

%.dis.pars.html: %.dis.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.dis.pars.non-tonal.vert: %.dis.pars.html
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.dis.pars.tonal.vert: %.dis.pars.html 
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"

%.repl.html: %.pars.html
	$(REPL) "$*" -fast

%.old.repl.html: %.old.pars.html
	$(REPL) "$*.old" -fast

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
		echo "Already applyed:" $< $$f ;\
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

compile: $(corpora-vert)

reparse-net: $(addsuffix .pars.html,$(netfiles))

reparse-net-vert: $(addsuffix .pars.non-tonal.vert,$(netfiles)) $(addsuffix .pars.tonal.vert,$(netfiles))

repl: $(replfiles)

repldiff: $(patsubst %.dis.html,%.repl.diff,$(dishtmlfiles))

freqlist.txt: corbama-net-tonal.vert
	python freqlist.py $< > $@

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

dist: $(compiled)
	echo $<	

dist-print:
	echo $(foreach corpus,$(corpora),export/data/$(corpus)/word.lex)

export/corbama.tar.xz: $(compiled)
	bash -c "pushd export ; tar cJvf corbama.tar.xz * ; popd"

create-testing:
	ssh $(HOST) 'test -d $(TESTING) || mkdir $(TESTING)'
	$(RSYNC) remote/*.sh $(HOST):
	ssh $(HOST) sh -x create-hsh.sh $(TESTING) $(TESTPORT)

setup-bonito:
	ssh $(HOST) hsh-run --rooter $(TESTING) -- 'sh setup-bonito.sh corbama $(corpora)' 

install-testing: export/corbama.tar.xz
	$(RSYNC) $< $(HOST):$(TESTING)/chroot/.in/
	ssh $(HOST) hsh-run --rooter $(TESTING) -- 'rm -rf /var/lib/manatee/{data,registry,vert}/corbama*'
	ssh $(HOST) hsh-run --rooter $(TESTING) -- 'tar --no-same-permissions --no-same-owner -xJvf corbama.tar.xz --directory /var/lib/manatee'

install-local: export/corbama.tar.xz
	sudo rm -rf /var/lib/manatee/{data,registry,vert}/corbama*
	sudo tar -xJvf $< --directory /var/lib/manatee --no-same-permissions --no-same-owner

start-%:
	ssh $(HOST) tmux new-session -d -s $* \"export share_network=1 \; hsh-shell --root --mount=/proc $*\"
	sleep 5
	ssh $(HOST) tmux send-keys -t $*:0 \"service httpd2 start\" Enter

stop-%:
	ssh $(HOST) tmux send-keys -t $*:0 \"service httpd2 stop\" Enter
	ssh $(HOST) tmux kill-session -t $*

production: stop-production stop-testing
	$(RSYNC) remote/testing2production.sh $(HOST):$(TESTING)/chroot/.in/
	ssh $(HOST) hsh-run --rooter $(TESTING) -- 'sh testing2production.sh $(TESTPORT) $(PRODPORT)'
	ssh $(HOST) sh -c 'test -d $(ROLLBACK)/chroot && hsh --clean $(ROLLBACK) || echo empty rollback'
	ssh $(HOST) rm -rf $(ROLLBACK)
	ssh $(HOST) mv $(PRODUCTION) $(ROLLBACK)
	ssh $(HOST) mv $(TESTING) $(PRODUCTION)

rollback: stop-production
	$(RSYNC) remote/testing2production.sh $(HOST):$(PRODUCTION)/chroot/.in/
	ssh $(HOST) hsh-run --rooter $(PRODUCTION) -- 'sh testing2production.sh $(PRODPORT) $(TESTPORT)'
	ssh $(HOST) sh -c 'test -d $(TESTING)/chroot && hsh --clean $(TESTING)'
	ssh $(HOST) rm -rf $(TESTING)
	ssh $(HOST) mv $(PRODUCTION) $(TESTING)
	ssh $(HOST) mv $(ROLLBACK) $(PRODUCTION)


corpsize:
	@echo "net:" `awk 'NF>1 && $$1 !~ /^</ && $$3 != "c" {print}' corbama-net-non-tonal.vert | wc -l`
	@echo "brut:" `awk 'NF>1 && $$1 !~ /^</ && $$3 != "c" {print}' corbama-brut.vert | wc -l`

corpsize-daba:
	@echo $(brutfiles) | tr ' ' '\n' | fgrep -v .dis | sed 's/.pars/.pars.html/' | xargs -n1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "brut:" c}'
#find -name \*.pars.html -print0 | xargs -0 -n 1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "brut:" c}'

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
