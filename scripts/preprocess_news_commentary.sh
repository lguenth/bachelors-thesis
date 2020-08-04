#!/bin/bash

#News Commentary v14: http://data.statmt.org/news-commentary/v14/training/news-commentary-v14.de-en.tsv.gz for Domain Adaptation

git clone https://github.com/moses-smt/mosesdecoder.git

MOSES=`pwd`/mosesdecoder

SCRIPTS=${MOSES}/scripts
TOKENIZER=${SCRIPTS}/tokenizer/tokenizer.perl
LC=${SCRIPTS}/tokenizer/lowercase.perl
CLEAN=${SCRIPTS}/training/clean-corpus-n.perl
URL="http://data.statmt.org/news-commentary/v14/training/news-commentary-v14.de-en.tsv.gz"
GZ=news-commentary-v14.de-en.tsv.gz

merge_ops=32000
src=de
tgt=en
lang=de-en
prep="test/data/nc"
tmp=${prep}/tmp
orig=orig
#the codes_file has to be created first
codes_file="${tmp}/bpe.${merge_ops}"

mkdir -p ${prep} ${tmp}

echo "Downloading data from ${URL}..."
cd ${orig}
curl -O "${URL}"

if [ -f ${GZ} ]; then
    echo "Data successfully downloaded."
else
    echo "Data not successfully downloaded."
    exit
fi

gunzip ${GZ}
cd ..

echo "Pre-processing data..."
cut -f1 ${data}.tsv > nc.${src}
cut -f2 ${data}.tsv > nc.${tgt}

for l in ${src} ${tgt}; do
	f=nc.$l
	tok=nc.tok.$l
	cat ${f} | \
	sed 's/@//g' ${f} | \
  perl ${TOKENIZER} -threads 8 -l $l > ${tmp}/${tok}
  echo ""
done

perl ${CLEAN} -ratio 1.5 ${tmp}/nc.tok ${src} ${tgt} ${tmp}/nc.clean 1 80

for l in ${src} ${tgt}; do
    perl ${LC} < ${tmp}/nc.clean.${l} > ${tmp}/nc.done.${l}
done

echo "Creating train, valid, test..."
for l in ${src} ${tgt}; do
#die ersten 100.000 Zeilen des Korpus werden zum Trainingsdatensatz
		head -100000 ${tmp}/nc.done.${l} > ${prep}/train.${l}
#die letzten 15.000 Zeilen des Korpus werden zum Evaluationsdatensatz
		tail -15000 ${tmp}/nc.done.${l} > ${tmp}/test.tmp.${l}
#der Evaluationsdatensatz wird jeweils zu Hälfte zur Validierung und zum Testen verwendet
		head -7500 ${tmp}/test.tmp.${l} > ${prep}/dev.${l}
		tail -7500 ${tmp}/test.tmp.${l} > ${prep}/test.${l}
done

echo "Applying BPE..."
for l in ${src} ${tgt}; do
    for p in train dev test; do
        python3 -m subword_nmt.apply_bpe -c "${codes_file}" -i "${prep}/${p}.${l}" -o "${prep}/${p}.bpe.${merge_ops}.${l}"
    done
done

rm -rf ${MOSES}
rm -rf ${tmp}
