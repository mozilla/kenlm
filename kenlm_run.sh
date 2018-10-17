#!/usr/bin/python3
import os
import glob
import subprocess

# Define directory for arpa files
arpa_directory = '/snakepit/home/kdavis/v0.3.0/arpa'

# Define directory for trie files
trie_directory = '/snakepit/home/kdavis/v0.3.0/trie'

# Define directory for probing files
probing_directory = '/snakepit/home/kdavis/v0.3.0/probing'

# Define paths to text corpora
librispeech_path = '/snakepit/shared/data/OpenSLR/SLR11/librispeech-lm-lc-norm.txt'

# Obtain limit vocab files
limit_vocab_files = glob.glob('/root/kenlm/librispeech-lm-lc-*-norm.txt')

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
            subprocess.run('/root/kenlm/build/bin/lmplz --memory 12%% --verbose_header --order %d --prune %s --interpolate_unigrams %d --text %s --arpa %s' % (order, prune_arg, interpolate_unigrams, librispeech_path, arpa_path), shell=True)
            for counter, limit_vocab_file in enumerate(limit_vocab_files):
                arpa_file = 'verbose_header_order=%d_prune=%d_interpolate_unigrams=%d_vocab_limit=%d.arpa' % (order, prune, interpolate_unigrams, (10000 + counter*5000))
                arpa_path = os.path.join(arpa_directory, arpa_file)
                print('Generating arpa %s' % arpa_path)
                subprocess.run('/root/kenlm/build/bin/lmplz --memory 12%% --verbose_header --order %d --prune %s --limit_vocab_file %s --interpolate_unigrams %d --text %s --arpa %s' % (order, prune_arg, limit_vocab_file, interpolate_unigrams, librispeech_path, arpa_path), shell=True)


# Generate probing models
for arpa_file in os.listdir(arpa_directory):
    if arpa_file.endswith('.arpa'):
        arpa_path = os.path.join(arpa_directory, arpa_file)
        print('Generating probing models from arpra path %s' % arpa_path)
        print('Generating probing models from arpra file %s' % arpa_file)
        for space_multiplier in [x * 0.1 for x in range(11, 102, 10)]:
            print('Generating probing model for space_multiplier %f' % space_multiplier)
            extensionless_arpa_file = os.path.splitext(arpa_file)[0]
            probing_file = (extensionless_arpa_file + '==space_multiplier=%f.probing') % (space_multiplier)
            probing_path = os.path.join(probing_directory, probing_file)
            subprocess.run('/root/kenlm/build/bin/build_binary -S 12%% -p %f probing %s %s' % (space_multiplier, arpa_path, probing_path), shell=True)


# Generate trie models
for arpa_file in os.listdir(arpa_directory):
    if arpa_file.endswith('.arpa'):
        arpa_path = os.path.join(arpa_directory, arpa_file)
        print('Generating trie models from arpra path %s' % arpa_path)
        print('Generating trie models from arpra file %s' % arpa_file)
        extensionless_arpa_file = os.path.splitext(arpa_file)[0]
        trie_file = extensionless_arpa_file + '.trie'
        trie_path = os.path.join(trie_directory, trie_file)
        subprocess.run('/root/kenlm/build/bin/build_binary -S 12%% trie %s %s' % (arpa_path, trie_path), shell=True)
        for bits in range(1, (max_bits + 1)):
            print('Generating trie models quantized to %d bits' % bits)
            for backoff in range(1, bits + 1):
                print('Generating trie models backed off to %d bits' % backoff)
                trie_file = (extensionless_arpa_file + '==q=%d_b=%d.trie') % (bits, backoff)
                trie_path = os.path.join(trie_directory, trie_file)
                subprocess.run('/root/kenlm/build/bin/build_binary -S 12%% trie -q %d -b %d %s %s' % (bits, backoff, arpa_path, trie_path), shell=True)
                print('Generating trie model with %d array max bits' % array_max_bits)
                trie_file = (extensionless_arpa_file + '==q=%d_b=%d_a=%d.trie') % (bits, backoff, array_max_bits)
                trie_path = os.path.join(trie_directory, trie_file)
                subprocess.run('/root/kenlm/build/bin/build_binary -S 12%% trie -q %d -b %d -a %d %s %s' % (bits, backoff, array_max_bits, arpa_path, trie_path), shell=True)
