#!/bin/bash

# set -x
#Paulo Nuin Jan 2015, modified Feb 15 - Aug 2016, Feb 2018

# TODO: set release version as a script argument
# TODO: not process XML files already processed

#set the version to be accessed
wbrel="WS263"
echo 'Release version' $wbrel


#################### Species ####################
#                                               #
#  species to be transferred                    #
#  key:value structure with species             #
#  "name" and BioProject number                 #
#  required in order to get the right           #
#  directory and file                           #
#                                               #
#################### Species ####################
#declare -A species=(["c_elegans"]="PRJNA13758"
#                    ["b_malayi"]="PRJNA10729"
#                    ["c_angaria"]="PRJNA51225"
#                    ["c_brenneri"]="PRJNA20035"
#                    ["c_briggsae"]="PRJNA10731"
#                    ["c_japonica"]="PRJNA12591"
#                    ["c_remanei"]="PRJNA53967"
#                    ["c_tropicalis"]="PRJNA53597"
#                    ["o_volvulus"]="PRJEB513"
#                    ["p_pacificus"]="PRJNA12644"
#                    ["p_redivivus"]="PRJNA186477"
#                    ["s_ratti"]="PRJEB125"
#                    ["c_sinica"]="PRJNA194557")

declare -A species=(["c_elegans"]="PRJNA13758")
echo 'Deploying ' $species
echo
#sourcedir='/mnt/data2/acedb_dumps/WS263/WS263-test-data'
# sourcedir='/mnt/data2/acedb_dumps/'$wbrel'' # <---- XML dump location
# example test data /mnt/data2/acedb_dumps/WS261/WS261-test-data
sourcedir='/Users/nuin/Dropbox/intermine/WS262-test-data/'

echo 'Source directory is at' $sourcedir
echo
#################### Main dirs ##################
#                                               #
#  datadir - main data directory                # 
#  acexmldir - subdir for AceDB XML files       #
#  pp - pre-processing dir with perl and bash   #
#                                               #
#################### Species ####################
# intermine='/mnt/data2/wormmine'
intermine='/Users/nuin/Dropbox/intermine/intermine'
#intermine='/Users/nuin/AeroFS/intermine_new/' #local test
#datadir=$intermine'/datadir_small'   # for now the datadir is inside the intermine directory
datadir=$intermine'/datadir'   # for now the datadir is inside the intermine directory
acexmldir=$datadir'/wormbase-acedb'
testlab=$intermine'/wormmine/support/scripts/'
compara=$intermine'/wormmine/support/compara'

echo 'WormMine datadir is at ' $intermine
echo 'AceDB directory is at ' $acexmldir
echo 'Perl scripts are at ' $testlab
echo

#################### FTP ########################
#################### Species #################### 
for spe in "${!species[@]}"
do
  
  echo species: $spe ${species["$spe"]}

  #################### get the genomic data ####################
  echo 'Getting genomic data'
  mkdir -vp $datadir'/fasta/'$spe"/genomic"
  cd $datadir'/fasta/'$spe"/genomic"
  if [ ! -f "$spe"."${species["$spe"]}"."$wbrel".genomic.fa ]; then
    echo "$spe"."${species["$spe"]}"."$wbrel".genomic.fa 'not found'
    echo 'transferring ' "$spe"."${species["$spe"]}"."$wbrel".genomic.fa.gz
    wget -q --show-progress -O "$spe"."${species["$spe"]}"."$wbrel".genomic.fa.gz "ftp://ftp.wormbase.org/pub/wormbase/releases/"$wbrel"/species/"$spe"/"${species["$spe"]}"/"$spe"."${species["$spe"]}"."$wbrel".genomic.fa.gz"
    gunzip  -v "$spe"."${species["$spe"]}"."$wbrel".genomic.fa.gz
  else
    echo "$spe"."${species["$spe"]}"."$wbrel".genomic.fa 'found, not transferring'
  fi
  echo

  #################### get the protein data ####################
  echo 'Getting protein data'
  mkdir -vp $datadir"/fasta/"$spe"/proteins/raw"
  mkdir -vp $datadir"/fasta/"$spe"/proteins/prepped"
  cd $datadir"/fasta/"$spe"/proteins/raw"
  if [ ! -f "$spe"."${species["$spe"]}"."$wbrel".protein.fa ]; then
    echo "$spe"."${species["$spe"]}"."$wbrel".protein.fa 'not found'
    echo 'transferring ' "$spe"."${species["$spe"]}"."$wbrel".protein.fa
    wget -q --show-progress -O "$spe"."${species["$spe"]}"."$wbrel".protein.fa.gz "ftp://ftp.wormbase.org/pub/wormbase/releases/"$wbrel"/species/"$spe"/"${species["$spe"]}"/"$spe"."${species["$spe"]}"."$wbrel".protein.fa.gz"
    gunzip -v "$spe"."${species["$spe"]}"."$wbrel".protein.fa.gz
  else
    echo "$spe"."${species["$spe"]}"."$wbrel".protein.fa 'found, not transferring'
  fi
  echo 'Pre-processing protein FASTA file'
  perl $testlab'/fasta/wb-proteins/prep-wb-proteins.pl' "$spe"."${species["$spe"]}"."$wbrel".protein.fa ../prepped/"$spe"."${species["$spe"]}"."$wbrel".protein.fa
  echo 

  ##################### get gff annotations ####################
  echo 'Getting gff data'
  mkdir -vp $datadir'/wormbase-gff3/raw'
  mkdir -vp $datadir'/wormbase-gff3/final'
  cd $datadir'/wormbase-gff3'
  if [ ! -f final/"$spe"."${species["$spe"]}"."$wbrel".gff ]; then
    echo 'transferring' "$spe"."${species["$spe"]}"."$wbrel".gff
    wget -q --show-progress -O raw/"$spe"."${species["$spe"]}"."$wbrel".gff.gz  "ftp://ftp.wormbase.org/pub/wormbase/releases/"$wbrel"/species/"$spe"/"${species["$spe"]}"/"$spe"."${species["$spe"]}"."$wbrel".annotations.gff3.gz"
    gunzip -v raw/"$spe"."${species["$spe"]}"."$wbrel".gff.gz
    echo 'Starting GFF3 pre-processing'

    bash "$intermine"/wormmine/support/scripts/gff3/scrape_gff3.sh $datadir/wormbase-gff3/raw/"$spe"."${species["$spe"]}"."$wbrel".gff $datadir/wormbase-gff3/final/"$spe"."${species["$spe"]}"."$wbrel".gff

    cd $datadir"/wormbase-gff3/final"
    python $testlab"/gff3/index.py" "$spe"."${species["$spe"]}"."$wbrel".gff
    rm "$spe"."${species["$spe"]}"."$wbrel".gff

    echo 'Done #########################'
  else
    echo  raw/"$spe"."${species["$spe"]}"."$wbrel".gff 'found'
  fi
  echo
done
# echo 'Setting up GFF3 mapping'
# mkdir -vp $datadir'/wormbase-gff3/mapping/'
# cp -v $intermine'/wormmine/support/properties/id_mapping.tab' $datadir'/wormbase-gff3/mapping/'
# cp -v $intermine'/wormmine/support/properties/typeMapping.tab' $datadir'/wormbase-gff3/mapping/'
# echo

#################### gene ontology ####################
mkdir -vp $datadir"/go/"
if [ ! -f $datadir/go/gene_ontology.1_2.obo ];then
  echo 'Transferring gene ontology file'
  wget -q --show-progress -O $datadir/go/gene_ontology.1_2.obo "ftp://ftp.wormbase.org/pub/wormbase/releases/"$wbrel"/ONTOLOGY/gene_ontology."$wbrel".obo"
else
  echo 'gene ontolgy file found'
fi
echo

#################### gene association #################
mkdir -vp $datadir'/go-annotation/raw/'
mkdir -vp $datadir'/go-annotation/final'

if [ ! -f $datadir'/go-annotation/final/gene_association_sorted_filtered.wb' ];then
  echo 'Transferring gene association file'
  wget -q --show-progress -O $datadir'/go-annotation/raw/gene_association'."$wbrel".wb "ftp://ftp.wormbase.org/pub/wormbase/releases/"$wbrel"/ONTOLOGY/gene_association."$wbrel".wb"
  echo 'Sorting'
  sort -k 2,2 $datadir'/go-annotation/raw/gene_association'."$wbrel".wb > $datadir'/go-annotation/raw/gene_association_sorted.wb'
  echo 'Filtering'
  bash $testlab'/go-annotation/filter_out_uniprot.sh' $datadir'/go-annotation/raw/gene_association_sorted.wb' $datadir'/go-annotation/final/gene_association_sorted_filtered.wb'
else
  echo 'gene association file found'
fi
echo


################### AceDB processing #################
######################################################

#################### anatomy term ####################
echo 'anatomy_term'
mkdir -vp $datadir/wormbase-acedb/anatomy_term/XML
mkdir -vp $datadir/wormbase-acedb/anatomy_term/mapping
cp -v $sourcedir/Anatomy_term.xml $acexmldir/anatomy_term/Anatomy_term.xml
cp -v $intermine'/wormmine/support/properties/anatomy_term_mapping.properties' $datadir'/wormbase-acedb/anatomy_term/mapping/'
perl $testlab'/wb-acedb/prep_anatomy_term.pl' $datadir'/wormbase-acedb/anatomy_term/Anatomy_term.xml' $datadir'/wormbase-acedb/anatomy_term/XML/Anatomy_term_prepped.xml'
echo

#################### cds #############################
echo 'cds'
mkdir -vp $datadir/wormbase-acedb/cds/XML
mkdir -vp $datadir/wormbase-acedb/cds/mapping
cp -v $sourcedir/CDS.xml $acexmldir/cds/CDS.xml
cp -v $intermine'/wormmine/support/properties/cds_mapping.properties' $datadir'/wormbase-acedb/cds/mapping/'
perl $testlab'/wb-acedb/purify_xace.pl' $datadir'/wormbase-acedb/cds/CDS.xml' $datadir'/wormbase-acedb/cds/purified_CDS.xml'
perl $testlab'/wb-acedb/prep_wb-acedb-cds.pl' $datadir'/wormbase-acedb/cds/purified_CDS.xml' $datadir'/wormbase-acedb/cds/XML/prepped_CDS.xml'
echo

#################### expression cluster ##############
echo 'expression cluster'
mkdir -vp $datadir/wormbase-acedb/expr_cluster/XML
mkdir -vp $datadir/wormbase-acedb/expr_cluster/mapping
cp -v $sourcedir/Expression_cluster.xml $acexmldir/expr_cluster/Expression_cluster.xml
cp -v $intermine'/wormmine/support/properties/expr_cluster_mapping.properties' $datadir'/wormbase-acedb/expr_cluster/mapping/'
perl $testlab'/wb-acedb/purify_xace.pl' $datadir'/wormbase-acedb/expr_cluster/Expression_cluster.xml' $datadir'/wormbase-acedb/expr_cluster/XML/purified_expression_cluster.xml'
echo

#################### expression pattern #############
echo 'expression pattern'
mkdir -vp $datadir/wormbase-acedb/expr_pattern/XML
mkdir -vp $datadir/wormbase-acedb/expr_pattern/mapping
cp -v $sourcedir/Expr_pattern.xml $acexmldir/expr_pattern/Expr_pattern.xml
cp -v $intermine'/wormmine/support/properties/expr_pattern_mapping.properties' $datadir'/wormbase-acedb/expr_pattern/mapping/'
perl $testlab'/wb-acedb/prep_expr_pattern.pl' $datadir'/wormbase-acedb/expr_pattern/Expr_pattern.xml' $datadir'/wormbase-acedb/expr_pattern/XML/Expr_pattern_prepped.xml'
echo

#################### gene ###########################
echo 'gene'
mkdir -vp $datadir/wormbase-acedb/gene/XML
mkdir -vp $datadir/wormbase-acedb/gene/mapping
cp -v $sourcedir/Gene.xml $acexmldir/gene/Gene.xml
cp -v $intermine'/wormmine/support/properties/wormbase-acedb-gene.properties' $datadir'/wormbase-acedb/gene/mapping/'
perl $testlab'/wb-acedb/purify_xace.pl' $datadir'/wormbase-acedb/gene/Gene.xml' $datadir'/wormbase-acedb/gene/purified_gene.xml'
perl $testlab'/wb-acedb/prep_wb-acedb-gene.pl' $datadir'/wormbase-acedb/gene/purified_gene.xml' $datadir'/wormbase-acedb/gene/XML/prepped_gene.xml'
rm $datadir/wormbase-acedb/gene/purified_gene.xml
echo

#################### life stage #####################
echo 'life stage'
mkdir -vp $datadir/wormbase-acedb/life_stage/XML
mkdir -vp $datadir/wormbase-acedb/life_stage/mapping
cp $sourcedir/Life_stage.xml $acexmldir/life_stage/Life_stage.xml
cp $intermine'/wb-acedb/wormmine/support/properties/life_stage_mapping.properties' $datadir'/wormbase-acedb/life_stage/mapping/'
perl $testlab'/wb-acedb/purify_xace.pl' $datadir'/wormbase-acedb/life_stage/Life_stage.xml' $datadir'/wormbase-acedb/life_stage/XML/purified_life_stage.xml'
echo

#################### phenotype #####################
echo 'phenotype'
mkdir -vp $datadir/wormbase-acedb/phenotype/XML
mkdir -vp $datadir/wormbase-acedb/phenotype/mapping
cp -v $sourcedir/Phenotype.xml $acexmldir/phenotype/Phenotype.xml
cp -v $intermine'/wormmine/support/properties/phenotype_mapping.properties' $datadir'/wormbase-acedb/phenotype/mapping'
perl $testlab'/wb-acedb/purify_xace.pl' $datadir'/wormbase-acedb/phenotype/Phenotype.xml' $datadir'/wormbase-acedb/phenotype/XML/purified_phenotype.xml'
echo

#################### protein #######################
echo 'protein'
mkdir -vp $datadir/wormbase-acedb/protein/XML
mkdir -vp $datadir/wormbase-acedb/protein/mapping
cp -v $sourcedir/Protein.xml $acexmldir/protein/Protein.xml
cp -v $intermine'/wormmine/support/properties/protein_mapping.properties' $datadir'/wormbase-acedb/protein/mapping'
perl $testlab'/wb-acedb/prep_wb-acedb-protein.pl' $datadir'/wormbase-acedb/protein/Protein.xml' $datadir'/wormbase-acedb/protein/prepped_protein.xml'
perl $testlab'/wb-acedb/purge_protein.pl' $datadir'/wormbase-acedb/protein/prepped_protein.xml' $datadir/'wormbase-acedb/protein/XML/purged_prepped_protein.xml' $testlab'/species_whitelist.txt' $datadir'/wormbase-acedb/protein/rejected_by_purge.xml'
rm $datadir/wormbase-acedb/protein/prepped_protein.xml
echo

#################### species #####################
echo 'species'
mkdir -vp $datadir/wormbase-acedb/species/XML
mkdir -vp $datadir/wormbase-acedb/species/mapping
cp -v $sourcedir/Species.xml $acexmldir/species/Species.xml
# cp -v $intermine'/wormmine/support/species_mapping.properties' $datadir'/wormbase-acedb/species/mapping'
mkdir -p $datadir/entrez-organism/build/
echo

#################### transcript ##################
echo 'transcript'
mkdir -vp $datadir/wormbase-acedb/transcript/XML
mkdir -vp $datadir/wormbase-acedb/transcript/mapping
cp -v $sourcedir/Transcript.xml $acexmldir/transcript/Transcript.xml
cp -v $intermine'/wormmine/support/properties/transcript_mapping.properties' $datadir'/wormbase-acedb/transcript/mapping'
perl $testlab'/wb-acedb/purify_xace.pl' $datadir'/wormbase-acedb/trasncript/Transcript.xml' $datadir'/wormbase-acedb/transcript/purified_transcript.xml'
perl $testlab'/wb-acedb/prep_wb-acedb-transcript.pl' $datadir'/wormbase-acedb/transcript/purified_transcript.xml' $datadir'/wormbase-acedb/transcript/XML/Transcript.xml'
echo

#################### RNAi #######################
echo 'RNAi'
mkdir -vp $datadir/wormbase-acedb/RNAi/XML
mkdir -vp $datadir/wormbase-acedb/RNAi/mapping
cp -v $sourcedir/RNAi.xml $acexmldir/RNAi/RNAi.xml
cp -v $intermine'/wormmine/support/properties/RNAi_mapping.properties' $datadir'/wormbase-acedb/RNAi/mapping'
perl $testlab'/wb-acedb/prep_RNAi.pl' $datadir'/wormbase-acedb/RNAi/RNAi.xml' $datadir'/wormbase-acedb/RNAi/prepped_RNAi.xml'
perl $testlab'/wb-acedb/prep_wb-acedb-RNAi.pl' $datadir'/wormbase-acedb/RNAi/prepped_RNAi.xml' $datadir'/wormbase-acedb/RNAi/XML/prepped_clean_RNAi.xml'
echo

#################### variation ##################
echo 'variation'
mkdir -vp $datadir/wormbase-acedb/variation/XML
mkdir -vp $datadir/wormbase-acedb/variation/mapping
cp -v $sourcedir/Variation.xml $acexmldir/variation/Variation.xml
cp -v $intermine'/wormmine/support/properties/variation_mapping.properties' $datadir'/wormbase-acedb/variation/mapping'
perl $testlab'/wb-acedb/purify_variation.pl' $datadir'/wormbase-acedb/variation/Variation.xml' $datadir'/wormbase-acedb/variation/XML/prepped_variation.xml'
sh $testlab'/wb-acedb/fix_elements_variation.sh' $acexmldir
echo

#################### gene_class #################
echo 'gene_class'
mkdir -vp $datadir/wormbase-acedb/gene_class/XML
mkdir -vp $datadir/wormbase-acedb/gene_class/mapping
cp -v $sourcedir/Gene_class.xml $acexmldir/gene_class/Gene_class.xml
cp -v $intermine'/wormmine/support/properties/gene_class_mapping.properties' $datadir'/wormbase-acedb/gene_class/mapping'
perl $testlab'/wb-acedb/prep_gene_class.pl' $datadir'/wormbase-acedb/gene_class/Gene_class.xml' $datadir'/wormbase-acedb/gene_class/XML/prepped_gene_class.xml'
echo

#################### strain  ##################
echo 'strain'
mkdir -vp $datadir/wormbase-acedb/strain/XML
mkdir -vp $datadir/wormbase-acedb/strain/mapping
cp -v $sourcedir/Strain.xml $acexmldir/strain/Strain.xml
cp -v $intermine'/wormmine/support/properties/strain_mapping.properties' $datadir'/wormbase-acedb/strain/mapping'
perl $testlab'/wb-acedb/prep_strain.pl' $datadir'/wormbase-acedb/strain/Strain.xml' $datadir'/wormbase-acedb/strain/XML/prepped_strain.xml'
echo

################### panther ######################
echo 'panther'
if [ ! -f $datadir'/panther/RefGenomeOrthologs' ];then
  mkdir -p $datadir'/panther'
  wget -O $datadir'/panther/RefGenomeOrthologs.tar.gz' ftp://ftp.pantherdb.org/ortholog/current_release/RefGenomeOrthologs.tar.gz
  tar xzvf $datadir'/panther/RefGenomeOrthologs.tar.gz' -C $datadir'/panther'
  rm -v $datadir'/panther/RefGenomeOrthologs.tar.gz'
else
  echo 'Panther already deployed'
fi
echo

################### id resolver ##################
echo 'ncbi'
if [ ! -f $datadir'/ncbi/gene_info' ];then
  mkdir -p $datadir'/ncbi'
  wget  -q --show-progress -O $datadir'/ncbi/gene_info.gz' "ftp://ftp.ncbi.nih.gov/gene/DATA/gene_info.gz"
  gunzip -v $datadir'/ncbi/gene_info.gz'
else
  echo 'NCBI gene_info already deployed'
fi
echo

echo 'wormid'
mkdir -p $datadir'/worm'
cp -v $intermine'/wormmine/support/panther/wormid' $datadir'/worm'
echo

echo 'idresolver'
mkdir -p $datadir'/idresolver'
ln -s $datadir'/ncbi/gene_info' $datadir'/idresolver/entrez'
ln -s $datadir'/worm/wormid' $datadir'/idresolver/wormid'
echo


################### compara #####################
echo 'compara - Human'
mkdir -p $datadir'/ensemble/compara'
perl $compara'/compara.pl' $compara'/human.xml' > $datadir'/ensemble/compara/6239_9606'

echo 'compara - Zebra'
mkdir -p $datadir'/ensemble/compara'
perl $compara'/compara.pl' $compara'/zebra.xml' > $datadir'/ensemble/compara/6239_7955'

echo 'compara - Mouse'
mkdir -p $datadir'/ensemble/compara'
perl $compara'/compara.pl' $compara'/mus.xml' > $datadir'/ensemble/compara/6239_10090'

echo 'compara - Drosophila'
mkdir -p $datadir'/ensemble/compara'
perl $compara'/compara.pl' $compara'/drosophila.xml' > $datadir'/ensemble/compara/6239_7227'

echo 'compara - Rat'
mkdir -p $datadir'/ensemble/compara'
perl $compara'/compara.pl' $compara'/rat.xml' > $datadir'/ensemble/compara/6239_10116'

echo 'compara - Yeast'
mkdir -p $datadir'/ensemble/compara'
perl $compara'/compara.pl' $compara'/yeast.xml' > $datadir'/ensemble/compara/6239_4932'



echo
echo 'Success: deployment and pre-processing complete'
echo

echo 'Starting build'
# cd $intermine'/wormmine'
# pwd
#../bio/scripts/project_build -b -v localhost wormmine_dump

