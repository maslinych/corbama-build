#!/usr/bin/env python

import re
import os
import sys
import spacy
import argparse
from spacy.tokens import Doc


def parse_arguments():
    parser = argparse.ArgumentParser(description='Lemmatize .fra.txt file and generate .vert')
    parser.add_argument('infile', help="Input file: .fra.txt line-sentence format")
    parser.add_argument('outfile', help="Output file (.vert format)")
    return parser.parse_args()


def tokenize_tags(line):
    out = []
    tag_re = re.compile('(</?[a-z]+[a-z_ "=0-9]*>)')
    toks = filter(None, tag_re.split(line))
    for t in toks:
        if tag_re.match(t):
            out.append(('tag', t))
        else:
            out.append(('text', t))
    return out


def read_sentences(filename):
    sent_re = re.compile('(?P<starttag><s n="[0-9]+">)(?P<senttext>.*?)</s>\\s*')
    with open(filename, 'r') as infile:
        for i, line in enumerate(infile):
            if line and not line.isspace():
                m = sent_re.match(line)
                if m:
                    yield (m.group('starttag'), m.group('senttext'))
                else:
                    sys.stderr.write('ERROR: Malformed line {}: {}'.format(i+1, line))
                    #sys.exit(1)


def lemmatize_document(parser, sents):
    for sentid, text in sents:
        docs = []
        toks = tokenize_tags(text)
        for tok in toks:
            if tok[0] == 'tag':
                words = [tok[1]]
                spaces = [False]
                pos = ['PUNCT']
                docs.append(parser(Doc(parser.vocab, words=words, spaces=spaces, pos=pos)))
            elif tok[0] == 'text':
                docs.append(parser(tok[1]))
        yield (sentid, Doc.from_docs(docs))


def format_morph(morph):
    d = morph.to_dict()
    return '|'.join([f'{key}={value}' for key, value in d.items()])


def format_sentence(sentid, sent):
    out = []
    out.append(sentid)
    for token in sent:
        out.append('\t'.join([str(token), token.lemma_, token.pos_,
                              format_morph(token.morph), token.dep_]))
    out.append('</s>')
    return '\n'.join(out) + '\n'


def main():
    args = parse_arguments()
    nlp = spacy.load('fr_core_news_md')
    ruler = nlp.get_pipe("attribute_ruler")
    sents = read_sentences(args.infile)
    doc = lemmatize_document(nlp, sents)
    sys.stderr.write("Processing file: {}...\n".format(args.infile))
    with open(args.outfile, 'w') as out:
        out.write('<doc id="{}">\n'.format(os.path.basename(args.infile)))
        for s in doc:
            out.write(format_sentence(*s))
        out.write('</doc>\n')


if __name__ == '__main__':
    main()
