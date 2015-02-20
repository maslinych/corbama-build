#!/bin/python
# -*- coding: utf-8 -*-

import sys
import re
from collections import Counter

ipm = False

isgrammar = lambda s: bool(re.match('[0-9A-Z._]+$', s))

freqs = Counter()

with open(sys.argv[1], 'rb') as infile:
    for line in infile:
        if not line.startswith('<'):
            fields = line.decode('utf-8').split('\t')
            try:
                if not fields[2] == 'c':
                    lemmas = fields[1].split('|')
                    lemmas.sort()
                    lemma = '|'.join(lemmas)
                    ps = [t for t in fields[2].split('|') if not re.match('[A-Z.0-9]+', t)]
                    ps.sort()
                    tag = '|'.join(ps)
                    gloss = u'-'.join([g for g in fields[3].split('-') if not isgrammar(g)]) or fields[3]
                    freqs[(lemma, tag, gloss)] += 1
            except IndexError:
                pass

if ipm:
    total = float(sum(freqs.values()))

for i, freq in enumerate(freqs.most_common()):
    lemma, count = freq
    out = [str(i+1), '\t'.join(lemma), str(count)]
    if ipm:
        out.append(str(round((count/total)*1000000, 2)))

    sys.stdout.write(u'{}\n'.format('\t'.join(out)).encode('utf-8'))

