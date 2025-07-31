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

## preparation pipeline
### trimgalore
````
# Create folder for FastQC results
mkdir -p fastqc_out

conda activate trimgalore
# Loop through all *_R1.fastq.gz (or _1.fastq) files and find matching pairs
for r1 in *_1*.fastq.gz
do
    # Get the sample name (assumes _R1 or _1 naming)
    base=$(basename "$r1" | sed 's/_R1.*.fastq//;s/_1.*.fastq//')

    # Infer R2 filename
    r2="${r1/_R1/_R2}"
    r2="${r2/_1/_2}"

    # Check if R2 exists
    if [[ -f "$r2" ]]; then
        echo "Trimming $base"

        trim_galore --paired "$r1" "$r2" \
    else
        echo "Warning: Missing R2 for $base"
    fi
done

# Move all FastQC output files to fastqc_out/
mv *_fastqc* fastqc_out/
conda deactivate
````
### multiqc
````
conda activate multiqc
multiqc fastqc_out -o multiqc_out
conda deactivate
````


## snippy
### prepare snippy list
````
### Snippy preparation
# Set the folder where your genomes are located
genome_folder <- "/path/to/your/genomes"

# List all FASTA files (adjust pattern if needed, e.g., .fa, .fasta, .fna)
genome_files <- list.files(path = genome_folder, pattern = "\\.(fa|fasta|fna|fastq)$", full.names = TRUE)

# Optional: sort files alphabetically
genome_files <- sort(genome_files)

# Output list to a text file
output_file <- file.path(genome_folder, "genome_list.txt")
writeLines(genome_files, con = output_file)
````
### run snippy
````
conda activate snippy
snippy-multi input.tab --ref reference/db11.gbk --cpus 12 > runme.sh
less runme.sh   # check the script makes sense
sh ./runme.sh   # leave it running over lunch
snippy-clean_full_aln core.full.aln > clean.full.aln
conda deactivate
````
### remove paraloges
````
conda activate gubbins
run_gubbins.py -p gubbins_ clean.full.aln --starting_tree clean.full.aln.treefile
python mask_gubbins_aln.py --aln clean.full.aln --gff gubbins_recombination_predictions.gff --out out.masked.aln
conda deactivate
````





