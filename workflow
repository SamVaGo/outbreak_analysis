# Annotate with bakta
````
conda activate bakta
FASTA_DIR="/Users/sam/phd/serratia/belgium_outbreaks/new_genomes/genomes"
OUTPUT_DIR="/Users/sam/phd/serratia/belgium_outbreaks/new_genomes/"

for fasta_file in "$FASTA_DIR"/*.fasta; do
    base_name=$(basename "$fasta_file" .fasta)
    bakta --db /Users/sam/db --threads 12 \
        --output /Users/sam/phd/serratia/belgium_outbreaks/new_genomes/"$base_name" \
        "$fasta_file"
done
conda deactivate
````
# move gff3 files
````
find /Users/sam/phd/clos/bakta -type f -name "*.gff3" -exec cp {} /Users/sam/phd/clos/gff3/ \;
````


