## Annotate with bakta
````
conda activate bakta
FASTA_DIR="/Users/sam/phd/serratia/belgium_outbreaks/MRSA/genomes"
OUTPUT_DIR="/Users/sam/phd/serratia/belgium_outbreaks/MRSA/bakta"

for fasta_file in "$FASTA_DIR"/*.fasta; do
    base_name=$(basename "$fasta_file" .fasta)
    bakta --db /Users/sam/db --threads 12 \
        --output "$OUTPUT_DIR"/"$base_name" \
        "$fasta_file"
done
conda deactivate
````
### move gff3 files
````
find /Users/sam/phd/serratia/belgium_outbreaks/MRSA/bakta/ -type f -name "*.gff3" -exec cp {} /Users/sam/phd/serratia/belgium_outbreaks/MRSA/gff3/ \;
````

## parsnp
````
parsnp -r /Users/sam/phd/serratia/belgium_outbreaks/reference_genome/ELP1_10.fna -d /Users/sam/phd/serratia/belgium_outbreaks/genomes -p 12
harvesttools -x parsnp.xmfa -M parsnp.fasta
````

## panaroo
````
conda activate panaroo
panaroo -i /Users/sam/phd/serratia/belgium_outbreaks/MRSA/gff3/*.gff3 -o /Users/sam/phd/serratia/belgium_outbreaks/MRSA/panaroo/ --remove-invalid-genes --clean-mode strict -a pan -t 12
conda deactivate
````

## IQTree
````
conda activate iqtree
iqtree -s /Users/sam/phd/serratia/belgium_outbreaks/MRSA/panaroo/core_gene_alignment_filtered.aln -m MFP -safe -T AUTO -ntmax 12
iqtree -s /Users/sam/phd/serratia/belgium_outbreaks/MRSA/panaroo/core_gene_alignment_filtered.aln -T AUTO -ntmax 12
conda deactivate
````

## snp_dists
````
conda activate snp-dists
snp-dists /Users/sam/phd/serratia/belgium_outbreaks/MRSA/panaroo/core_gene_alignment_filtered.aln > /Users/sam/phd/serratia/belgium_outbreaks/MRSA/snp_dist.tsv
conda deactivate
````

# cg/wgMLST using chewbbaca
````
conda activate chewbbaca
````

## Create a wgMLST schema
````
chewBBACA.py CreateSchema -i /Users/sam/phd/serratia/belgium_outbreaks/MRSA/genomes -o /Users/sam/phd/serratia/belgium_outbreaks/MRSA/chewbbaca/schema --ptf /Users/sam/phd/serratia/belgium_outbreaks/MRSA/chewbbaca/Staphylococcus_aureus.trn
````

## AlleleCall - Determine the allelic profiles of a set of genomes
````
chewBBACA.py AlleleCall -i /Users/sam/phd/serratia/belgium_outbreaks/MRSA/genomes -g /Users/sam/phd/serratia/belgium_outbreaks/MRSA/chewbbaca/schema/schema_seed -o /Users/sam/phd/serratia/belgium_outbreaks/MRSA/chewbbaca/results_wgMLST --cpu 12
````

## ExtractCgMLST - Determine the set of loci that constitute the core genome
````
chewBBACA.py ExtractCgMLST -i /Users/sam/phd/serratia/belgium_outbreaks/MRSA/chewbbaca/results_wgMLST/results_alleles.tsv -o /Users/sam/phd/serratia/belgium_outbreaks/MRSA/chewbbaca/results_cgMLST
````

````
conda deactivate
````






