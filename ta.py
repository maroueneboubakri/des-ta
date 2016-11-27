#! /usr/bin/env python2
#
# Marouene Boubakri, marouene.boubakri@eurecom.fr
#
# Copyright (C) Telecom ParisTech
# 
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
#

import sys
import argparse
import des
import km
import pcc
import re

def main ():
    # ************************************************************************
    # * Before doing anything else, check the correctness of the DES library *
    # ************************************************************************
    if not des.check ():
        sys.exit ("DES functional test failed")

    # *************************************
    # * Check arguments and read datafile *
    # *************************************
    argparser = argparse.ArgumentParser(description="Apply P. Kocher's TA algorithm")
    argparser.add_argument("datafile", metavar='file', 
                        help='name of the data file (generated with ta_acquisition)')
    argparser.add_argument("n", metavar='n', type=int,
                        help='number of experiments to use')
    args = argparser.parse_args()

    if args.n < 1:                                      # If invalid number of experiments.
        sys.exit ("Invalid number of experiments: %d (shall be greater than 1)" % args.n)

    # Read encryption times and ciphertexts. n is the number of experiments to use.
    read_datafile (args.datafile, args.n)

    rk = bk = 0x000000000000
    dl = 0
    dla = []

    for sbox in reversed(xrange(8)):
	mask = 0x3f << (0x2a - 6*sbox)
	rk &= ~mask
	for i in range(64):
		key =  i << (42 - 6*sbox)		
                ctx = pcc.pccContext (1)
                for j in range(args.n):
                        #Undoes the final permutation on cipher text of n-th experiment.
                        r16l16 = des.ip (ct[j])
                        #Extract right half (strange naming as in the DES standard).
                        l16 = des.right_half (r16l16)
                        #Compute output of SBoxes during last round of first experiment, assuming the last round key is all zeros.
                        sbo = des.sboxes (des.e (l16) ^ (rk | key))
                        #Compute Hamming weight of output SBox
                        hw = hamming_weight (sbo)
                        ctx.insert_x(t[j])
                        ctx.insert_y(0, hw)
                ctx.consolidate ()
                dli = ctx.get_pcc(0)
		dla.append(dli)
		if dli > dl:
			dl = dli
			bk = key
	dl = 0
	rk |= bk	
	
	dla.sort(reverse=True)

    # ************************************
    # * Compute and print average timing *
    # ************************************
    print >> sys.stderr, "Average timing: %f" % (sum (t) / args.n)

    # ************************
    # * Print last round key *
    # ************************
    print >> sys.stderr, "Last round key (hex):"
    print >> sys.stderr, "0x%012X" % rk
    print "0x%012X" % rk


    # ************************
    # * Verification *
    # ************************
	
    #with open('ta.key', 'r') as key_file:
    #	keys = key_file.read()

    #if int(re.findall(re.compile('0[xX][0-9a-fA-F]{12}[ ]'), keys)[15], 16) == rk:
    #	print "0x%012x" % rk

    
# Open datafile <name> and store its content in global variables
# <ct> and <t>.
def read_datafile (name, n):
    global ct, t

    if not isinstance (n, int) or n < 0:
        raise ValueError('Invalid maximum number of traces: ' + str(n))

    try:
        f = open (str(name), 'rb')
    except IOError:
        raise ValueError("cannot open file " + name)
    else:
        try:
            ct = []
            t = []
            for _ in xrange (n):
                a, b = f.readline ().split ()
                ct.append (int(a, 16))
                t.append (float(b))
        except (EnvironmentError, ValueError):
            raise ValueError("cannot read cipher text and/or timing measurement")
        finally:
            f.close ()


# ** Returns the Hamming weight of a 64 bits word.
# * Note: the input's width can be anything between 0 and 64, as long as the
# * unused bits are all zeroes.
# See: http://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
def hamming_weight (v):
    v = v - ((v>>1) & 0x5555555555555555)
    v = (v & 0x3333333333333333) + ((v>>2) & 0x3333333333333333)
    return (((v + (v>>4) & 0xF0F0F0F0F0F0F0F) * 0x101010101010101) >> 56) & 0xFF

if __name__ == "__main__":
    main ()
