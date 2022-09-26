#!/usr/bin/env python3
# coding: utf-8

import os
import re
import unittest
import subprocess
import itertools
from collections import defaultdict, OrderedDict


class ParallelCorpusTestCase(unittest.TestCase):
    """Integrity checks for input data of a Bambara-French parallel corpus"""
    def setUp(self):
        tests_dir = os.path.dirname(os.path.abspath(__file__))
        self.root_dir = os.path.dirname(tests_dir)
        self.corbama_dir = os.path.join(os.path.dirname(self.root_dir), 'corbama')
        # filelists .prl & .fra.txt
        self.prl = subprocess.check_output(["git", "-C", self.corbama_dir, "ls-files", "*.bam-fra.prl"], text=True, encoding='utf-8').strip('\n').split('\n')
        self.fra = subprocess.check_output(["git", "-C", self.corbama_dir, "ls-files", "*.fra.txt"], text=True, encoding='utf-8').strip('\n').split('\n')
        # Bambara sources filelist
        self.bam = list(filter(lambda s: not s.endswith('.fra.txt'),
                               subprocess.check_output(["git", "-C",
                                                   self.corbama_dir, "ls-files", "*.dis.html",
                                                        "*.html", "*.txt", "*.bam.txt"], text=True,
                                                       encoding='utf-8').strip('\n').split('\n')))
        self.bam_txt = list(filter(lambda s: s.endswith('.bam.txt'), self.bam))
        self.bam_src = list(filter(lambda s: not s.endswith('.bam.txt'), self.bam))
        self.built_bam_txt = []
        prl_basenames = map(self.strip_suffix('.bam-fra.prl'), self.prl)
        bam_txt_basenames = list(map(self.strip_suffix('.bam.txt'), self.bam_txt))
        for b in prl_basenames:
            if b not in bam_txt_basenames:
                self.built_bam_txt.append(''.join([b, '.bam.txt']))
        # Parse sentence tags in bam/fra.txt files and collect results
        self.txt_len = {}
        for f in itertools.chain(self.fra, self.bam_txt, self.built_bam_txt):
            self.txt_len[f] = self.parse_txt(f)
        # Parse compiled vertfiles
        self.corbamafara = self.parse_vertfile(os.path.join(self.root_dir, 'corbamafara.vert'))
        self.corfarabama = self.parse_vertfile(os.path.join(self.root_dir, 'corfarabama.vert'))
        self.prl_joined_bam, self.prl_joined_fra = self.check_prl_syntax(os.path.join(self.root_dir, 'corbama-bam-fra.prl'))

    def strip_suffix(self, pattern, regex=False):
        """Strip filename suffix, plain string or regex"""
        if regex:
            return lambda s: re.sub(pattern, '', s)
        else:
            return lambda s: s.rsplit(pattern, 1)[0]

    def locate_file(self, filename):
        """Locate file either in corbama-build or corbama"""
        corbama_filename = os.path.join(self.corbama_dir, filename)
        if os.path.exists(corbama_filename):
            return corbama_filename
        else:
            return os.path.join(self.root_dir, filename)

    def check_prl_syntax(self, filename):
        """Check syntax in a .prl file"""
        infile = self.locate_file(filename)
        with open(infile, 'r') as prlfile:
            max_sent = defaultdict(int)
            for lineno, line in enumerate(prlfile, start=1):
                if line.startswith('<doc'):
                    continue
                fields = line.strip('\n').split('\t')
                self.assertEqual(len(fields), 2, msg='ERROR: Incorrect number of fields in a prl file %s:%s — %d' % (filename, lineno, len(fields)))
                if len(fields) == 2:
                    for fno, f in enumerate(fields, start=1):
                        m = re.match('(?P<empty>-1$)|(?P<single>[0-9]+$)|(?P<range>(?P<range_a>[0-9]+)[:,](?P<range_b>[0-9]+)$)', f)
                        if m:
                            if m.group('range'):
                                try:
                                    A = int(m.group('range_a'))
                                    if A > 0 or max_sent[fno] > 0:
                                        self.assertEqual(1, A-max_sent[fno],
                                                         'ERROR: consecutive sentence numbering violated %s:%s — %d→%d' % (filename, lineno, max_sent[fno], A))
                                    B = int(m.group('range_b'))
                                    max_sent[fno] = B
                                except TypeError:
                                    self.fail('ERROR: incorrect range format: %s:%s — %s' % (filename, lineno, m.group('range')))
                                self.assertGreater(B, A, msg='ERROR: Incorrect sentence range %s:%s %d—%d' % (filename, lineno, A, B))
                            elif m.group('single'):
                                try:
                                    S = int(m.group('single'))
                                    if S > 0 or max_sent[fno] > 0:
                                        self.assertEqual(1, S-max_sent[fno],
                                                         'ERROR: consecutive sentence numbering violated %s:%s — %d→%d' % (filename, lineno, max_sent[fno], S))
                                    max_sent[fno] = S
                                except TypeError:
                                    self.fail('ERROR: incorrect number format: %s:%s — %s' % (filename, lineno, m.group('single')))
                        else:
                            self.fail('ERROR: Unrecognized line format: %s:%s' % (filename, lineno))
        return (max_sent[1], max_sent[2])

    def parse_txt(self, filename):
        """Locate sentence tags in a bam/fra.txt file"""
        sent_re = '(?P<starttag><s[ ]+n="(?P<id>[0-9]+)"\s*>)(.|\n(?!<s n=))*(?P<endtag></s>)'
        infile = self.locate_file(filename)
        with open(infile, 'r') as txtfile:
            out = []
            txt = txtfile.read()
            for s in re.finditer(sent_re, txt, re.MULTILINE):
                s_id = int(s.group('id'))
                out.append(s_id)
        return out
        
    def check_txt(self, filename):
        """Check sentence numbering consistency in a bam/fra.txt file"""
        sent_ids = self.txt_len[filename]
        if not sent_ids:
            self.fail('ERROR: no sentence tags found in %s' % filename)
        last_sent = 0
        for s_id in sent_ids:
            with self.subTest(sno=s_id):
                prev_id = int(last_sent)
                last_sent = s_id
                if prev_id > 0 and s_id > 0:
                    self.assertEqual(1, s_id - prev_id, msg='ERROR: consecutive sentence numbering violated in %s: %d→%d' % (filename, prev_id, s_id))

    def get_nsent(self, filename):
        """Number of sentences in a bam/fra.txt file"""
        try:
            return self.txt_len[filename][-1]
        except IndexError:
            return 0

    def parse_vertfile(self, filename):
        """Extract list and order of documents in a compiled .vert file"""
        docid_re = re.compile(r'<doc id="(?P<id>[^"]+?)(([.]pars)?[.]html|[.]fra[.]txt)"')
        out = OrderedDict()
        nsent = None
        docid = None
        with open(filename, 'r') as infile:
            for line in infile:
                if line.startswith('<doc'):
                    if docid:
                        out[docid] = nsent
                    nsent = 0
                    try:
                        m = re.match(docid_re, line)
                        docid = m.group('id')
                    except AttributeError:
                        print("ERROR: docid not found in header: %s" % line)
                elif re.match('^<s[ >].*', line):
                    nsent += 1
            out[docid] = nsent
        return out

    longMessage = False

    def test_prl_has_fra(self):
        """check that every .bam-fra.prl file has a corresponding .fra.txt file in git"""
        fra_basenames = list(map(self.strip_suffix('.fra.txt'), self.fra))
        for f in self.prl:
            de_prl = self.strip_suffix('.bam-fra.prl')
            with self.subTest(f=f):
                self.assertIn(de_prl(f), fra_basenames, msg='ERROR: .fra.txt is missing for %s' % f)

    def test_fra_has_prl(self):
        """check that every .bam-fra.prl file has a corresponding .fra.txt file in git"""
        prl_basenames = list(map(self.strip_suffix('.bam-fra.prl'), self.prl))
        de_fra = self.strip_suffix('.fra.txt')
        for f in self.fra:
            with self.subTest(f=f):
                self.assertIn(de_fra(f), prl_basenames, msg='ERROR: .bam-fra.prl is missing for %s' % f)

    def test_prl_has_bam(self):
        """check that every .bam-fra.prl file has a corresponding source or built .bam.txt file"""
        all_bam = itertools.chain(self.bam_txt, self.built_bam_txt)
        for f in self.prl:
            de_prl = self.strip_suffix('.bam-fra.prl')
            with self.subTest(f=f):
                bam_path = self.locate_file(''.join([de_prl(f), '.bam.txt']))
                self.assertTrue(os.path.exists(bam_path), msg='ERROR: .bam.txt is not found at %s' % bam_path)

    def test_prl_file_syntax(self):
        """Test .prl files for syntactic correctness"""
        for f in self.prl:
            with self.subTest(f=f):
                nbam, nfra = self.check_prl_syntax(f)

    def test_fra_txt_syntax(self):
        """Test .fra.txt files for syntactic correctness"""
        for f in self.fra:
            with self.subTest(f=f):
                nsents = self.check_txt(f)

    def test_bam_txt_syntax(self):
        """Test .bam.txt files for syntactic correctness"""
        for f in itertools.chain(self.bam_txt, self.built_bam_txt):
            with self.subTest(f=f):
                nsents = self.check_txt(f)

    def test_prl_match_txt_length(self):
        """Check that number of sentences in .prl matches that in .txt files"""
        for f in self.prl:
            with self.subTest(f=f):
                base = self.strip_suffix('.bam-fra.prl')(f)
                nbam, nfra = self.check_prl_syntax(f)
                bam_txt = base + '.bam.txt'
                fra_txt = base + '.fra.txt'
                if bam_txt in self.built_bam_txt:
                    ntxt = self.get_nsent(bam_txt)
                    self.assertEqual(nbam, ntxt, msg='last sentence number in %s does not match %s: %d, %d' % (f, bam_txt, nbam, ntxt))
                if fra_txt in self.fra:
                    ntxt = self.get_nsent(fra_txt)
                    self.assertEqual(nfra, ntxt, msg='last sentence number in %s does not match %s: %d, %d' % (f, fra_txt, nfra, ntxt))

    def test_corbamafara_has_all_prl(self):
        """Check that every .prl file has a corresponding doc in corbamafara.vert"""
        prl_basenames = map(os.path.basename, map(self.strip_suffix('.bam-fra.prl'), self.prl))
        for prl_id in prl_basenames:
            with self.subTest(f=prl_id):
                self.assertIn(prl_id, self.corbamafara.keys(), msg="ERROR: %s is missing in corbamafara.vert" % prl_id)

    def test_corbamafara_has_no_extra_ids(self):
        """Check that there's no docs not listed in .prl files in corbamafara.vert"""
        prl_basenames = map(os.path.basename, map(self.strip_suffix('.bam-fra.prl'), self.prl))
        for doc_id in self.corbamafara.keys():
            with self.subTest(f=doc_id):
                self.assertIn(doc_id, prl_basenames, msg="ERROR: %s included in corbamafara.vert is not listed in .prl files" % doc_id)

    def test_corfarabama_has_all_prl(self):
        """Check that every .prl file has a corresponding doc in corbamafara.vert"""
        prl_basenames = map(os.path.basename, map(self.strip_suffix('.bam-fra.prl'), self.prl))
        fra_basenames = map(os.path.basename, map(self.strip_suffix('.fra.txt'), self.corfarabama))
        for prl_id in prl_basenames:
            with self.subTest(f=prl_id):
                self.assertIn(prl_id, self.corfarabama.keys(), msg="ERROR: %s is missing in corfarabama.vert" % prl_id)

    def test_corfarabama_has_no_extra_ids(self):
        """Check that there's no docs not listed in .prl files in corbamafara.vert"""
        prl_basenames = map(os.path.basename, map(self.strip_suffix('.bam-fra.prl'), self.prl))
        for doc_id in self.corfarabama.keys():
            with self.subTest(f=doc_id):
                self.assertIn(doc_id, prl_basenames, msg="ERROR: %s included in corfarabama.vert is not listed in .prl files" % doc_id)

    def test_both_filelists_aligned(self):
        """Test that files go in the same order in corbamafara.vert and corfarabama.vert"""
        self.assertTrue(list(self.corbamafara) == list(self.corfarabama), msg="ERROR: sequences of files are not aligned in corbamafara/corfarabama")

    def test_numsent_match_prl(self):
        """Check that number of <s> tags in corbama/fara matches .prl files"""
        for f in self.prl:
            with self.subTest(f=f):
                base = os.path.basename(self.strip_suffix('.bam-fra.prl')(f))
                nbam, nfra = self.check_prl_syntax(f)
                bam_nsent = self.corbamafara[base] - 1
                fra_nsent = self.corfarabama[base] - 1
                self.assertEqual(nbam, bam_nsent, msg="ERROR: %s numsent in corbamafara (%d) doesn't match prl (%d)" % (base, bam_nsent, nbam))
                self.assertEqual(nfra, fra_nsent, msg="ERROR: %s numsent in corfarabama (%d) doesn't match prl (%d)" % (base, fra_nsent, nfra))

    def test_joined_bam_prl_length(self):
        """Check that total length of joined .prl file in sentences equals the sum of all included .prl files"""
        totbam = 0
        joined_bam = self.prl_joined_bam + 1
        for f in self.prl:
            nbam, _ = self.check_prl_syntax(f)
            totbam += nbam + 1
        self.assertEqual(totbam, joined_bam, msg='ERROR: total number of BAMANA sentences in joined .prl file (%s) does not match the sum of individual files (%s)' % (joined_bam, totbam))

    def test_joined_fra_prl_length(self):
        """Check that total length of joined .prl file in sentences equals the sum of all included .prl files"""
        totfra = 0
        joined_fra = self.prl_joined_fra + 1
        for f in self.prl:
            _, nfra = self.check_prl_syntax(f)
            totfra += nfra + 1
        self.assertEqual(totfra, joined_fra, msg='ERROR: total number of FRENCH sentences in joined .prl file (%s) does not match the sum of individual files (%s)' % (joined_fra, totfra))

if __name__ == '__main__':
    unittest.main()

