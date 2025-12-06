# Bits eliminated in lossy compression

For reducing the size of BLOW5 files, we can perform non-reversible lossy compression using `slow5tools degrade`. More details about this compression strategy is available in our [Genome Research publication](https://genome.cshlp.org/content/35/7/1574).

The number of bits eliminated when using `slow5tools degrade` with the default `-b auto` option is documented here.

In the table below, slow5tools version column indicates from which version the profile is available. `.` means not yet available.

| Experiment type | Sequencing Kit   | Device              | Sample frequency | slow5tools version | Bits eliminated |
| --------------- | ---------------- | ------------------- | ---------------- | ------------------ | --------------- |
| dna             | sqk-lsk109       | GridION             | 4000             | .                  | .               |
| dna             | sqk-lsk109       | MinION              | 4000             | .                  | .               |
| dna             | sqk-lsk109       | PromethION          | 4000             | 1.3.0              | 2               |
| dna             | sqk-lsk109       | PromethION p2_solo  | 4000             | 1.3.1              | 2               |
| dna             | sqk-lsk110       | GridION             | 4000             | 1.3.1              | 3               |
| dna             | sqk-lsk110       | MinION              | 4000             | 1.3.1              | 3               |
| dna             | sqk-lsk110       | PromethION          | 4000             | 1.3.1              | 2               |
| dna             | sqk-lsk110       | PromethION  p2_solo | 4000             | 1.3.1              | 2               |
| dna             | sqk-lsk112       | GridION             | 4000             | 1.3.0              | 3               |
| dna             | sqk-lsk112       | MinION              | 4000             | 1.3.1              | 3               |
| dna             | sqk-lsk112       | PromethION          | 4000             | 1.3.1              | 3               |
| dna             | sqk-lsk112       | PromethION  p2_solo | 4000             | 1.3.1              | 3               |
| dna             | sqk-lsk114       | GridION             | 4000             | 1.3.1              | 3               |
| dna             | sqk-lsk114       | GridION             | 5000             | 1.3.1              | 3               |
| dna             | sqk-lsk114       | MinION              | 4000             | 1.3.1              | 3               |
| dna             | sqk-lsk114       | MinION              | 5000             | 1.3.0              | 3               |
| dna             | sqk-lsk114       | PromethION          | 4000             | 1.3.0              | 3               |
| dna             | sqk-lsk114       | PromethION          | 5000             | 1.3.0              | 3               |
| dna             | sqk-lsk114       | PromethION  p2_solo | 4000             | 1.3.1              | 3               |
| dna             | sqk-lsk114       | PromethION  p2_solo | 5000             | 1.3.1              | 3               |
| dna             | sqk-mlk111-96-xl | PromethION          | 4000             | .                  | .               |
| dna             | sqk-mlk111-96-xl | PromethION  p2_solo | 4000             | .                  | .               |
| dna             | sqk-nbd114-24    | PromethION          | 4000             | 1.3.1              | 3               |
| dna             | sqk-nbd114-24    | PromethION          | 5000             | 1.3.1              | 3               |
| dna             | sqk-nbd114-24    | PromethION  p2_solo | 4000             | 1.3.1              | 3               |
| dna             | sqk-nbd114-24    | PromethION  p2_solo | 5000             | 1.3.1              | 3               |
| dna             | sqk-pcb109       | PromethION          | 4000             | .                  | .               |
| dna             | sqk-pcb109       | PromethION  p2_solo | 4000             | .                  | .               |
| dna             | sqk-rad004       | PromethION          | 4000             | 1.3.1              | 2               |
| dna             | sqk-rad004       | PromethION  p2_solo | 4000             | 1.3.1              | 2               |
| dna             | sqk-rbk004       | GridION             | 4000             | .                  | .               |
| dna             | sqk-rbk004       | MinION              | 4000             | .                  | .               |
| dna             | sqk-rbk004       | PromethION          | 4000             | .                  | .               |
| dna             | sqk-rbk004       | PromethION  p2_solo | 4000             | .                  | .               |
| dna             | sqk-ulk001       | PromethION          | 4000             | .                  | .               |
| dna             | sqk-ulk001       | PromethION  p2_solo | 4000             | .                  | .               |
| dna             | sqk-ulk114       | PromethION          | 5000             | 1.3.1              | 3               |
| dna             | sqk-ulk114       | PromethION  p2_solo | 5000             | 1.3.1              | 3               |
| rna             | sqk-rna002       | GridION             | 3000             | .                  | .               |
| rna             | sqk-rna002       | MinION              | 3000             | .                  | .               |
| rna             | sqk-rna002       | PromethION          | 3000             | 1.3.0              | 2               |
| rna             | sqk-rna002       | PromethION  p2_solo | 3000             | 1.3.1              | 2               |
| rna             | sqk-rna004       | PromethION          | 4000             | 1.3.0              | 3               |
| rna             | sqk-rna004       | PromethION  p2_solo | 4000             | 1.3.1              | 3               |