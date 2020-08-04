#! /bin/bash

git clone https://github.com/moses-smt/mosesdecoder.git

MOSES=mosesdecoder
SCRIPTS=${MOSES}/scripts
DETOKENIZER=${SCRIPTS}/tokenizer/detokenizer.perl
TC=${SCRIPTS}/recaser/truecase.perl
TRAINTC=${SCRIPTS}/recaser/train-truecaser.perl

# change file names here
tgt=en
hyps=hyps.en
orig=orig.en

# undoing bpe and remove any tags

cat ${hyps} | sed 's/\@\@ //g' | sed 's/<pad>//g' | \
sed "s/<unk> /'/g" | sed "s/<unk>//g" | sed 's/&#91; /[/g' | \
sed 's/&#93; /]/g' | sed 's/&quot;/"/g' > ${hyps}.clean

# training truecaser with original (unprocessed) file

./${TRAINTC} --model truecaser --corpus ${orig}

# truecasing test hypothesis

./${TC} --model truecaser < ${hyps}.clean > ${hyps}.tc

# uppercasing first letter of each sentence

awk ' {$0=toupper(substr($0,1,1))substr($0,2); print } ' ${hyps}.tc | sed 's/[.?!"]\s*./\U&\E/g' > ${hyps}.tc.upper

# detokenizing hypothesis

cat ${hyps}.tc.upper | ./${DETOKENIZER} -l ${tgt} > ${hyps}.done
