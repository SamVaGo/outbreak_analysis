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
conda deactivate
````
### multiqc
````
conda activate multiqc
mkdir -p fastqc_out
fastqc *.fq.gz -o fastqc_out -t 12
multiqc fastqc_out -o multiqc_out -t 12
conda deactivate
````


## snippy
### prepare snippy list
````
# Set the folder where your trimmed FASTQ files are located
fastq_folder <- "/path/to/your/trimmed_fastq"

# List all R1 (forward) reads
r1_files <- list.files(path = fastq_folder, pattern = "_1_val_1\\.fq\\.gz$", full.names = TRUE)

# Extract isolate names (before _1_val_1)
isolate_names <- sub("_1_val_1\\.fq\\.gz$", "", basename(r1_files))

# Construct matching R2 file paths
r2_files <- file.path(fastq_folder, paste0(isolate_names, "_2_val_2.fq.gz"))

# Sanity check: ensure R2 files exist
if (!all(file.exists(r2_files))) {
  stop("Some R2 files are missing!")
}

# Create a data frame
snippy_list <- data.frame(
  Isolate = isolate_names,
  R1 = r1_files,
  R2 = r2_files
)

# Write to a tab-delimited text file
output_file <- file.path(fastq_folder, "snippy_samples.tsv")
write.table(snippy_list, file = output_file, sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)

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

## assembly with spades
### Input and output directories
````
input_dir="/Users/sam/phd/serratia/PRJNA609822/fastq"
output_base="/Users/sam/phd/serratia/PRJNA609822/fasta"
````

### Make sure output directory exists
````
mkdir -p "$output_base"
````

### Loop over all R1 FASTQ files
````
for r1 in "$input_dir"/*_1_val_1.fq.gz
do
    # Get the isolate name (basename without _1_val_1.fq.gz)
    base=$(basename "$r1" | sed 's/_1_val_1\.fq\.gz//')
    
    # Define R2 file
    r2="$input_dir/${base}_2_val_2.fq.gz"

    # Define SPAdes output folder
    spades_out="$output_base/${base}_spades"

    # Check that R2 exists
    if [[ ! -f "$r2" ]]; then
        echo "❗ Missing R2 for $base — skipping"
        continue
    fi

    echo "🧬 Running SPAdes for $base"
    spades.py -1 "$r1" -2 "$r2" -o "$spades_out" -t 12
done
````
### copy paste the fasta files to a new directory and rename
# Set the directory where SPAdes subfolders are located
````
spades_dir="/Users/sam/phd/serratia/PRJNA609822/fasta"
output_dir="${spades_dir}/renamed_contigs"
````

# Create output directory
````
mkdir -p "$output_dir"
````

# Loop through each subdirectory
````
for folder in "$spades_dir"/*_spades; do
    if [[ -d "$folder" && -f "$folder/contigs.fasta" ]]; then
        sample_name=$(basename "$folder" | sed 's/_spades$//')
        cp "$folder/contigs.fasta" "$output_dir/${sample_name}.fasta"
    fi
done
````



