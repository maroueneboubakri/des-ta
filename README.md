# des-ta
Timing attack against a DES software implementation

This repository contains PoC files. 

ta_acquisition generates a ta.dat file containing a pair of cipher/exectime and a ta.key contianing the secret key and the 16 rounds keys

ta.py is the timing attack script. It extracts the final round key given the acquisitions data file and the number of experiments.



