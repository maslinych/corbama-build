## Bambara Reference Corpus Sources

### Files included

Corbama (BRC corpus short name) is subdivided into two subcorpora:

* Manually disambiguated subcorpus (corbama-net\* files), approx. 0.35M words
* Full subcorpus, including disambiguated and non-disambiguated parts (corbama-brut and corbama-nul), approx. 2.1M words.

Both subcorpora come in two variants which differ in the orthography and the amount of tonal marking represented.

* `corbama-net-non-tonal.vert` : Disambiguated subcorpus, tones absent (as in source texts).
* `corbama-net-tonal.vert` : Disambiguated subcorpus, tones automatically added on word and lemma fields.
* `corbama-brut.vert` : Full subcorpus (with non-disambiguated part), tones absent.
* `corbama-nul.vert` : Full subcorpus with simplified orthography (open vowels replaced with their closed counterparts o,e), tones absent.

### Annotation scheme

Corpus sources are compiled in vertical format as required by
SketchEngine. Set of fields and structures are documented in config
files for corresponding corpora included in `config` subdirectory).
For the format of config files and vertical file format see
SketchEngine docs:
http://www.sketchengine.co.uk/documentation/wiki/SkE/PreparingCorpusOverview

Short notes on the semantics of the fields:

* **word** : normalized word form (new latin Bambara orthography,
  qutomatically added tones when appicable);
* **lemma** : automatically generated lemma, also normalized
  orthography and tones where applicable. In non-disambiguated
  contains all possible interpretations of the wordform provided by
  the rule-based parser Daba as an alternative lemmas.
* **tag** : part of speech tag (one or more) plus grammatical tags of the
  derivative morphemes
* **gloss** : French or standardized gloss. In non-disambiguated texts
  — list of possible variants.
* **parts** : for derivative composite words a list of constituent
  stems.
* **original** : original wordform as it is in the text (not
  normalized)
* **tonal** : for non-tonal variants : form with automatically added
  tones
* **polysemy** : for polysemous words — alternative glosses



