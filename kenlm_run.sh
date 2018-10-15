#!/usr/bin/python
import os
import glob

# Define directory for arpa files
arpa_directory = '/snakepit/uploads/v0.3.0/arpa'

# Define directory for trie files
trie_directory = '/snakepit/uploads/v0.3.0/trie'

# Define directory for probing files
probing_directory = '/snakepit/uploads/v0.3.0/probing'

# Define paths to text corpora
librispeech_path = '/snakepit/shared/data/OpenSLR/SLR11/librispeech-lm-lc-norm.txt'

# Obtain limit vocab files
limit_vocab_files = glob.glob('librispeech-lm-lc-*-norm.txt')

# Define global constants
max_bits = 25
min_order = 2
max_order = 6
array_max_bits = 255

# Generate arpa models
for order in range(min_order, max_order + 1):
    print('Creating ARPA models of order %d' % order)
    for prune in range(min_order, order + 1):
        print('ARPA pruning starts at %d' % prune)
        prune_arg = ' '.join(['0' if index != (prune-1) else '1' for index in range(0, prune)])
        for interpolate_unigrams in range(0, 2):
            print('Interpolate unigrams set to %d' % interpolate_unigrams)
            arpa_file = 'verbose_header_order=%d_prune=%d_interpolate_unigrams=%d.arpa' % (order, prune, interpolate_unigrams)
            arpa_path = os.path.join(arpa_directory, arpa_file)
            print('Generating arpa %s' % arpa_path)
            !build/bin/lmplz --memory 50% --verbose_header --order {order} --prune {prune_arg} --interpolate_unigrams {interpolate_unigrams} --text {librispeech_path} --arpa {arpa_path}
            for counter, limit_vocab_file in enumerate(limit_vocab_files):
                arpa_file = 'verbose_header_order=%d_prune=%d_interpolate_unigrams=%d_vocab_limit=%d.arpa' % (order, prune, interpolate_unigrams, (10000 + counter*5000))
                arpa_path = os.path.join(arpa_directory, arpa_file)
                print('Generating arpa %s' % arpa_path)
                !build/bin/lmplz --memory 50% --verbose_header --order {order} --prune {prune_arg} --limit_vocab_file {limit_vocab_file} --interpolate_unigrams {interpolate_unigrams} --text {librispeech_path} --arpa {arpa_path}


# Generate probing models
for arpa_path in os.listdir(arpa_directory):
    if arpa_path.endswith('.arpa'):
        print('Generating probing models from arpra path %s' % arpa_path)
        arpa_file = os.path.basename(arpa_path)
        print('Generating probing models from arpra file %s' % arpa_file)
        for space_multiplier in [x * 0.1 for x in range(11, 102, 10)]:
            print('Generating probing model for space_multiplier %f' % space_multiplier)
            extensionless_arpa_file = os.path.splitext(arpa_file)[0]
            probing_file = (extensionless_arpa_file + '==space_multiplier=%f.probing') % (space_multiplier)
            probing_path = os.path.join(probing_directory, probing_file)
            !build/bin/build_binary -S 50% -p {space_multiplier} probing {arpa_path} {probing_path}


# Generate trie models
for arpa_path in os.listdir(arpa_directory):
    if arpa_path.endswith('.arpa'):
        print('Generating trie models from arpra path %s' % arpa_path)
        arpa_file = os.path.basename(arpa_path)
        print('Generating trie models from arpra file %s' % arpa_file)
        extensionless_arpa_file = os.path.splitext(arpa_file)[0]
        trie_file = extensionless_arpa_file + '.trie'
        trie_path = os.path.join(trie_directory, trie_file)
        !build/bin/build_binary -S 50% trie {arpa_path} {trie_path}
        for bits in range(1, (max_bits + 1)):
            print('Generating trie models quantized to %d bits' % bits)
            for backoff in range(1, bits + 1):
                print('Generating trie models backed off to %d bits' % backoff)
                trie_file = (extensionless_arpa_file + '==q=%d_b=%d.trie') % (bits, backoff)
                trie_path = os.path.join(trie_directory, trie_file)
                !build/bin/build_binary -S 50% trie -q {bits} -b {backoff} {arpa_path} {trie_path}
                print('Generating trie model with %d array max bits' % array_max_bits)
                trie_file = (extensionless_arpa_file + '==q=%d_b=%d_a=%d.trie') % (bits, backoff, array_max_bits)
                trie_path = os.path.join(trie_directory, trie_file)
                !build/bin/build_binary -S 50% trie -q {bits} -b {backoff} -a {array_max_bits} {arpa_path} {trie_path}
