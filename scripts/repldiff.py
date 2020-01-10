#!/usr/bin/env python
# coding: utf-8

import sys

hunkleft = []
hunkright = []
newhunk = True


def compare_hunk(hunkleft, hunkright):
    out = []
    if not len(hunkleft) == len(hunkright):
        return out
    for left, right in zip(hunkleft, hunkright):
        try:
            if left[0].startswith('-<') and right[0].startswith('+<'):
                continue
            elif left[0].startswith('---') and right[0].startswith('+++'):
                continue
            elif '|' in left[1] or '|' in left[2] or '|' in left[3]:
                continue
            elif '|' in right[1]:
                continue
            elif not left[1] == right[1]:
                out.append((left, right, u'{} != {}'.format(left[1], right[1])))
            elif not left[2] == right[2]:
                out.append((left, right, u'{} != {}'.format(left[2], right[2])))
            elif not left[3] == right[3]:
                out.append((left, right, u'{} != {}'.format(left[3], right[3])))
        except IndexError:
            print "ERR", left, right
    return out


def print_hunk(discrepancies):
    for left, right, reason in discrepancies:
        sys.stdout.write(u'{}\n'.format(reason).encode('utf-8'))
        sys.stdout.write(u'-{}\n'.format(u'\t'.join(left)).encode('utf-8'))
        sys.stdout.write(u'+{}\n'.format(u'\t'.join(right)).encode('utf-8'))
        sys.stdout.write('\n')
   

for line in sys.stdin:
    li = line.decode('utf-8').strip()
    if li.startswith('-'):
        if newhunk:
            discrepancies = compare_hunk(hunkleft, hunkright)
            if discrepancies:
                print_hunk(discrepancies)
            hunkleft = []
            hunkright = []
            newhunk = False
        fields = li.split("\t")
        hunkleft.append(fields)
    elif li.startswith('+'):
        newhunk = True
        fields = li.split("\t")
        hunkright.append(fields)
            
        
