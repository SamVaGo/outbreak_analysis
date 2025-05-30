# Annotate with bakta
````
conda activate bakta
FASTA_DIR="/Users/sam/phd/clos/fasta"
OUTPUT_DIR="/Users/sam/phd/clos/bakta/"

for fasta_file in "$FASTA_DIR"/*.fasta; do
    base_name=$(basename "$fasta_file" .fasta)
    bakta --db /Users/sam/db --threads 8 --output "$OUTPUT_DIR"/$base_name 
    "$fasta_file"
done
conda deactivate
````
