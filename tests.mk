# unresolved ambiguity left in corbama-net
reports := tests/net-ambiguous-gloss.txt tests/net-ambiguous-pos.txt tests/net-empty-pos.txt

all: $(reports)

test: all

tests/net-ambiguous-lemma.txt: corbama-net-tonal.conll
	awk -F"\t" '$$0 ~ /^# <doc/ {d=$$0;next} NF == 3 {s=s " " $$1} $$3 ~ /.[|]./ {amb=$$0} $$2 == "SENT" {if (amb) {print d; print s; print amb; print ""; amb=""}; s="";}' $< > $@

tests/net-ambiguous-pos.txt: corbama-net-tonal.conll
	awk -F"\t" '$$0 ~ /^# <doc/ {d=$$0;next} NF == 3 {s=s " " $$1} $$2 ~ /.[|]./ {amb=$$0} $$2 == "SENT" {if (amb) {print d; print s; print amb; print ""; amb=""}; s="";}' $< > $@

tests/net-empty-pos.txt: corbama-net-tonal.conll
	awk -F"\t" '$$0 ~ /^# <doc/ {d=$$0;next} NF == 3 {s=s " " $$1} !length($$2) {empty=$$0} $$2 == "SENT" {if (empty) {print d; print s; print empty; print ""; empty=""}; s="";}' $< > $@

tests/net-lemma-too-long.txt: corbama-net-non-tonal.conll
	awk -F"\t" '$$0 ~ /^# <doc/ {d=$$0;next} NF == 3 {s=s " " $$1} length($$3)-length($$1) > 2 {toolong=$$0} $$2 == "SENT" {if (toolong) {print d; print s; print toolong; print ""; toolong=""}; s="";}' $< > $@
