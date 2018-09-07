#!/usr/bin/env python
# coding: utf-8

from __future__ import print_function
import argparse
import sys


def read_prls(filelist):
    ainc, binc = (-1, -1)
    amax, bmax = (0, 0)
    for f in filelist:
        print(u"<doc={}>".format(f).encode('utf8'))
        with open(f, 'r+') as prl:
            ainc = ainc + amax + 1
            binc = binc + bmax + 1
            amax, bmax = (0, 0)
            for line in prl:
                pair = line.decode('utf-8-sig').strip().split('\t')
                a, b = map(parse_align, pair)
                amax, bmax = map(max, zip((amax, bmax), map(get_last, (a, b))))
                astr = increment_align(a, ainc)
                bstr = increment_align(b, binc)
                yield (astr, bstr)
                

def parse_align(afield):
    try:
        numlist = [int(i) for i in afield.split(',')]
        return ('list', numlist)
    except ValueError:
        try:
            numrange = [int(i) for i in afield.split(':')]
            return ('range', numrange)
        except ValueError:
            sys.stderr.write(u"Malformed line: '{}', I'll skip it\n".format(afield).encode('utf-8'))
            return ('strange', afield)


def get_last(parsed_field):
    if parsed_field[0] == 'strange':
        return -1
    else:
        return max(parsed_field[1])


def increment_align(parsed_field, inc):
    ftype, fvalue = parsed_field
    if ftype == 'strange':
        return fvalue
    if fvalue == [-1]:
        return "-1"
    newvalues = [str(i+inc) for i in fvalue]
    if ftype == 'list':
        return ','.join(newvalues)
    elif ftype == 'range':
        return ':'.join(newvalues)


def main():
    def parse_arguments():
        parser = argparse.ArgumentParser(
            description='Concatenate .prl files intelligently')
        parser.add_argument('infiles', help="Input files", nargs='+')
        return parser.parse_args()
    args = parse_arguments()

    for source, target in read_prls(args.infiles):
        print('{0}\t{1}'.format(source, target).encode('utf-8'))


if __name__ == '__main__':
    main()
