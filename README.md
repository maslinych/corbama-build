## Bambara Reference Corpus Build Infrastructure

This repository binds together all procedures required to build corpus
indexes for the
[Bambara Reference Corpus](http://cormand.huma-num.fr/).

### Build process overview

1. Clone this repository
2. Install tools
3. Clone repositories with corpus resources
4. `cd corbama-build`
5. run `make`

#### Get tools

A list of tools build process depends on:

* GNU Make and UNIX command line environment (bash, coreutils, sed, awk etc.)
* [NoSketchEngine](http://nlp.fi.muni.cz/trac/noske/wiki/Downloads) —
  you'll need `manatee-open` package.
* [Daba](https://github.com/maslinych/daba). Clone this repo into the
  same directory where `corbama-build` resides.

#### Get corpus resources

Corpus resources are corpus source files and dictionaries. 
By default all resources are expected to reside at the parent
directory of the corbama-build copy. 

* `corbama` — a corpus repository (private, not shown)
* `bamadaba` — a lexical database, clone from
  [github](https://github.com/maslinych/bamadaba).
  

#### Run build procedure

Provided that you have directory structure as shown,

```
./
	bamadaba/
	corbama/
	corbama-build/
	daba/
```

simply run:

```bash
$ cd corbama-build
$ make makedirs
$ make resources
$ make compile
```

The process is time-consuming and may be sped up by using `make -jN`
option with the number of processors/cores available for parallel
build.

#### Publishing a corpus

To publish a corpus online you'll need to have a server set up for running NoSketchEngine's web engine 
bonito-open in a chrooted environment (for more details, see below). 

Two environments are used for publishing: 

* *testing* — for initial upload and experiments;
* *production* — for a stable corpus serving users.

**NB** Several different corpora may share a single environment (both 
testing and production). In such a case, watch out that your operations
on one corpus do not overwrite other corpora in the same environment.

Thus, following steps need to be performed:

1. Create a testing environment (if not created before for some other corpus):

```bash
$ make create-testing
```

2. Setup bonito-open config files for your corpus:

```bash
$ make setup-bonito
```

3. Upload your corpus to the testing environment:

```bash
$ make install-testing
```

4. Start web-server in the testing environment and examine the corpus:

```bash
$ make start-testing
```

5. When ready, transform the testing environment into production.
**Remember** that if your corpus is not alone in the environment, you 
**must** upload all other corpora into the same testing environment
prior to performing this step.

```bash
$ make production
$ make start-production
```

### Corpus files that are built

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
* **polisemy** : for polysemous words — alternative glosses
* **tagstring**: structure of ps tags on source Gloss object

### Corpus server setup

To run an online corpus search engine you'll need:

* A [Sisyphus](http://sisyphus.ru/en/)-based GNU/Linux operation system on a server.
* Packages `hasher hasher-priv tmux` installed on a server.
* A regular user on a sever with ssh access and setup for running two parallel hasher processes. To provide for the latter, you'll need to run as root: 

```bash
$ hasher-useradd <your_user>
$ hasher-useradd --number=1 <your_user>
```
* A web-server: nginx (recommended) or any other for proxying HTTP-requests to the corpora that will reside in chrooted environments. You will need to setup proxy for requests to testing and production. Ports where corresponding web-servers will be listening are listed in the Makefile in TESTPORT and PRODPORT variables.
* On your local machine, setup ssh access credentials for the corpus user on the server in `.ssh/config` and place the corresponding host name in Makefile in the variable HOST (by default it uses hostname `corpora`).

You're done, all the rest will be handled by Makefile commands listed in the *Publishing a corpus* section of this README.

