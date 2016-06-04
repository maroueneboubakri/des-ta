# des-ta
Timing attack against a DES software implementation

Usage
-----
If you want to test the attack script, you have to generate a time measurement database

    $./ta_acquisition 100000

ta.py is used as a standalone script. It takes as argument the acquisitions file and a the number of experiments to run.

    $python ta.py ta.dat 10000



PoC
---

**ta.py** is my timing attack script. It extracts the final round key given the acquisitions data file and the number of experiments.

Lab files
---------

**des.py** Data Encryption Standard algorithm implementation library

**km** library, to manage the partial knowledge about a DES secret key

**ta_acquisition** generates a ta.dat file containing a pair of cipher/exectime and a ta.key contianing the secret key and the 16 rounds keys

**pcc.py**  Pearson Correlation Coefficients computation library

**ta.key** containing the 64-bits DES secret key, its 56-bits version (without the parity bits), the 16 corresponding 48-bits round keys and, for each round key, the eight 6-bits subkeys.

**ta.dat** containing the 100000 ciphertexts and timing measurements.





