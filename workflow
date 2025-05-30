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
find /Users/sam/phd/serratia/belgium_outbreaks/new_genomes/ -type f -name "*.gff3" -exec cp {} /Users/sam/phd/serratia/belgium_outbreaks/gff3/ \;
````

## panaroo
conda activate panaroo
panaroo -i /Users/sam/phd/serratia/belgium_outbreaks/gff3/*.gff3 --clean-mode strict -a core --aligner mafft  --remove-invalid-genes -o /Users/sam/phd/serratia/belgium_outbreaks/panaroo -t 8
conda deactivate
