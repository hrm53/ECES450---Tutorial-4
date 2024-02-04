echo ${containerdir}
echo $SLURM_CPUS_PER_TASK
indir=${containerdir}

ls ${indir}/ # load sequences

qiime tools import \
  --type 'EMPSingleEndSequences' \
  --input-path ${indir}/emp-single-end-sequences \
  --output-path ${indir}/emp-single-end-sequences.qza

qiime tools peek ${indir}/emp-single-end-sequences.qza

qiime demux emp-single \
  --i-seqs ${indir}/emp-single-end-sequences.qza \
  --m-barcodes-file ${indir}/sample-metadata.tsv \
  --m-barcodes-column ${indir}/barcode-sequence \
  --o-per-sample-sequences ${indir}/demux.qza \
  --o-error-correction-details ${indir}/demux-details.qza

qiime demux summarize \
  --i-data ${indir}/demux.qza \
  --o-visualization ${indir}/demux.qzv

qiime tools view ${indir}/demux.qzv

qiime dada2 denoise-single \
  --p-n-threads $SLURM_CPUS_PER_TASK \
  --i-demultiplexed-seqs ${indir}/demux.qza \
  --p-trim-left 0 \
  --p-trunc-len 120 \
  --o-representative-sequences ${indir}/rep-seqs.qza \
  --o-table ${indir}/table.qza \
  --o-denoising-stats ${indir}/stats.qza

qiime metadata tabulate \
  --m-input-file ${indir}/stats.qza \
  --o-visualization ${indir}/stats.qzv

qiime tools view ${indir}/stats.qzv

qiime quality-filter q-score \
  --p-n-threads $SLURM_CPUS_PER_TASK \
  --i-demux ${indir}/demux.qza \
  --o-filtered-sequences ${indir}/demux-filtered.qza \
  --o-filter-stats ${indir}/demux-filter-stats.qza

qiime deblur denoise-16S \
  --p-n-threads $SLURM_CPUS_PER_TASK \
  --i-demultiplexed-seqs ${indir}/demux-filtered.qza \
  --p-trim-length 120 \
  --p-sample-stats \
  --o-representative-sequences ${indir}/rep-seqs-deblur.qza \
  --o-table ${indir}/table-deblur.qza \
  --o-stats ${indir}/deblur-stats.qza

qiime metadata tabulate \
  --m-input-file ${indir}/demux-filter-stats.qza \
  --o-visualization ${indir}/demux-filter-stats.qzv

qiime deblur visualize-stats \
  --i-deblur-stats ${indir}/deblur-stats.qza \
  --o-visualization ${indir}/deblur-stats.qzv

qiime tools view ${indir}/deblur-stats.qzv

# q2cli:
mv rep-seqs-deblur.qza rep-seqs.qza
mv table-deblur.qza table.qza
# Artifact API:
table = table_deblur
rep_seqs = rep_seqs_deblur

qiime feature-table summarize \
  --i-table ${indir}/table.qza \
  --m-sample-metadata-file ${indir}/sample-metadata.tsv \
  --o-visualization ${indir}/table.qzv
qiime feature-table tabulate-seqs \
  --i-data ${indir}/rep-seqs.qza \
  --o-visualization ${indir}/rep-seqs.qzv

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences ${indir}/rep-seqs.qza \
  --output-dir ${indir}/phylogeny-align-to-tree-mafft-fasttree

qiime diversity core-metrics-phylogenetic \
  --i-phylogeny ${indir}/phylogeny-align-to-tree-mafft-fasttree/rooted_tree.qza \
  --i-table ${indir}/table.qza \
  --p-sampling-depth 1103 \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --output-dir ${indir}/diversity-core-metrics-phylogenetic

qiime diversity alpha-group-significance \
  --i-alpha-diversity ${indir}/diversity-core-metrics-phylogenetic/faith_pd_vector.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --o-visualization ${indir}/faith-pd-group-significance.qzv
qiime diversity alpha-group-significance \
  --i-alpha-diversity ${indir}/diversity-core-metrics-phylogenetic/evenness_vector.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --o-visualization ${indir}/evenness-group-significance.qzv

qiime diversity beta-group-significance \
  --i-distance-matrix ${indir}/diversity-core-metrics-phylogenetic/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --m-metadata-column body-site \
  --p-pairwise \
  --o-visualization ${indir}/unweighted-unifrac-body-site-group-significance.qzv
qiime diversity beta-group-significance \
  --i-distance-matrix ${indir}/diversity-core-metrics-phylogenetic/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --m-metadata-column subject \
  --p-pairwise \
  --o-visualization ${indir}/unweighted-unifrac-subject-group-significance.qzv

qiime emperor plot \
  --i-pcoa ${indir}/diversity-core-metrics-phylogenetic/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --p-custom-axes days-since-experiment-start \
  --o-visualization ${indir}/unweighted-unifrac-emperor-days-since-experiment-start.qzv
qiime emperor plot \
  --i-pcoa diversity-core-metrics-phylogenetic/bray_curtis_pcoa_results.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --p-custom-axes days-since-experiment-start \
  --o-visualization ${indir}/bray-curtis-emperor-days-since-experiment-start.qzv

qiime diversity alpha-rarefaction \
  --i-table ${indir}/table.qza \
  --i-phylogeny ${indir}/phylogeny-align-to-tree-mafft-fasttree/rooted_tree.qza \
  --p-max-depth 4000 \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --o-visualization ${indir}/alpha-rarefaction.qzv

qiime feature-classifier classify-sklearn \
  --i-classifier ${indir}/gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads ${indir}/rep-seqs.qza \
  --o-classification ${indir}/taxonomy.qza
qiime metadata tabulate \
  --m-input-file ${indir}/taxonomy.qza \
  --o-visualization ${indir}/taxonomy.qzv

qiime taxa barplot \
  --i-table ${indir}/table.qza \
  --i-taxonomy ${indir}/taxonomy.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --o-visualization ${indir}/taxa-bar-plots.qzv

qiime feature-table filter-samples \
  --i-table ${indir}/table.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --p-where '[body-site]='"'"'gut'"'"'' \
  --o-filtered-table ${indir}/gut-table.qza

qiime composition add-pseudocount \
  --i-table ${indir}/gut-table.qza \
  --o-composition-table ${indir}/comp-gut-table.qza

qiime composition ancom \
  --i-table ${indir}/comp-gut-table.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --m-metadata-column subject \
  --o-visualization ${indir}/ancom-subject.qzv

qiime taxa collapse \
  --i-table ${indir}/gut-table.qza \
  --i-taxonomy ${indir}/taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table ${indir}/gut-table-l6.qza
qiime composition add-pseudocount \
  --i-table ${indir}/gut-table-l6.qza \
  --o-composition-table ${indir}/comp-gut-table-l6.qza
qiime composition ancom \
  --i-table ${indir}/comp-gut-table-l6.qza \
  --m-metadata-file ${indir}/sample-metadata.tsv \
  --m-metadata-column subject \
  --o-visualization ${indir}/l6-ancom-subject.qzv
