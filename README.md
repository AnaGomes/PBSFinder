PBSFinder - Protein binding site finder
=========

PBSFinder is a web platform aimed at biologists and investigators in the areas of Biology and Bioinformatics. It takes a list of gene identifiers and finds protein binding sites for those genes. Behind the scenes it aggregates information from several other platforms, crosses that information and presents it in an easy to understand way.

## Usage

PBSFinder is an account driven application, meaning that you need to register an account to be able to use the platform. This allows us to associate each job to the user that created it, enabling users to manage their own jobs. At this time users can share jobs between each other using direct links. This is not a design overlook, as we think that researchers should be able to easily share interesting information.

After registering an account, an user can create a job, specifying a job description and a list of gene identifiers. Jobs make take from a few seconds to several minutes, depending on the number of identifiers, number of different species, etc. For long running jobs the user has 3 options to view the results: going to their job list, on the finished jobs tab; following the link on their job notification email (if they choose to receive one); staying on the same page, as it will reload once the job is finished.

### Input formats

At this moment the platform supports 5 different identifier types:

* Ensembl Gene ID
* Ensembl Transcript ID
* Entrez ID
* GenBank Nucleotide Accession
* RefSeq mRNA Accession

You can mix identifier types at your leisure. The jobs also support identifiers from multiple organisms. However, only organisms present in the latest Ensembl release are supported (available at http://www.ensembl.org/info/genome/stable_ids/index.html).

### Output formats

TODO

### Using PBSFinder on your own

TODO

## Behind the scenes

TODO

### Application structure

TODO

### Data persistance

TODO

### Used services and APIs

TODO

## Future work

TODO

© 2014 Diogo Teixeira. This code is distributed under the MIT license.
