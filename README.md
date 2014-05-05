PBSFinder - Protein binding site finder
=========

PBSFinder is a web platform aimed at biologists and investigators in the areas of Biology and Bioinformatics. It takes a list of gene identifiers and finds protein binding sites for those genes. Behind the scenes it aggregates information from several other platforms, crosses that information and presents it in an easy to understand way.

## Usage

PBSFinder is an account driven application, meaning that you need to register an account to be able to use the platform. This allows us to associate each job to the user that created it, enabling users to manage their own jobs. At this time users can share jobs between each other using direct links. This is not a design overlook, as I think that researchers should be able to easily share interesting information.

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

By default results are presented in two different views, the job view and the transcript view.

In the job view you'll have a table with every gene identifier that was provided, their respective transcripts (if any) and an indication wether it binds or not with a specific protein. On top of that, you'll have links to each gene's information pages (either NCBI or Ensembl) and links to each protein's information pages (UniProt). This information is complemented with a bar chart that shows the most common RBPs.

In the transcript view you'll have transcript specific information, like genetic sequences (5'/3' UTR, 3' downstream), species and a table listing all RBPs, their confidence level, binding sequences and places. You'll also have a bar chart that shows with how many places a given protein can bind. 

### Using PBSFinder on your own

Feel free to use your own PBSFinder installation. Before trying to run PBSFinder, be sure to check every item in this list:

* Linux system (possibly OSX too, I don't have a way to test)
* Ruby (best results with RVM)
* MongoDB

You'll find two Gemfiles in the repository, one for each application. If you use RVM, you can use the same gemset for both, there shouldn't be any conflicts (although I prefer independent gemsets). Other than that, just having a standard MongoDB should work out of the box, you can let Mongoid worry about the specificities of database creation. 

## Behind the scenes

Below I'll briefly explain some of PBSFinder's inner workings, so you can better understand if it suits your needs.

### Application structure

The project is divided in two applications, a web app and a job server. The web app itself is a simple Padrino app, without anything worth mentioning. As you might have guessed, jobs may take a long time to run and in some cases are very resource intensive. As such, you don't want to strain your web application front end.

I solved this problem using distributed Ruby. Whenever someone creates a new job, the web app sends a request to the distributed Ruby server, with the identifier list, some more internal data and the name of the class of worker that should be instantiated to solve that request. The server than instantiates the worker, gives it all the data and launches a new thread to run that worker. When the worker finishes it notifies the server, and is removed from the running list. Notice that for some reason the server is shutdown, it will resume any unfinished workers next time it runs.

### Data persistance

At this moment, data is stored in a MongoDB database, in essentially two collections: Account and Job.

Account contains all the user info that is relevant to the user system: name, login, password (hashed), etc.

Job contains all the information of a given job. It has several levels of embedded documents. I chose this structure mainly because the sub documents (Gene, Transcript, etc.) don't have any significance outside a job's context. Despite that, I am aware of the MongoDB document size limitations (16mb at the moment) and may change this structure in the future, if documents become too large.

### Used services and APIs

For now I'll just list all the services that I'm using behind PBSFinder. At a later time I'll describe the type of usage of each one in detail.

* bioDBnet (http://biodbnet.abcc.ncifcrf.gov/db/db2db.php)
* Ensembl Biomart (http://www.ensembl.org/biomart/martview/)
* NCBI EUtils (http://www.ncbi.nlm.nih.gov/books/NBK25500/)
* UniProt (http://www.uniprot.org/uniprot/)
* RBPDB (http://rbpdb.ccbr.utoronto.ca)

## Future work

I'm currenyly looking into incorporating inductive logic programming (with Prolog), in order to cluster genes and RBPs by some of their properties. At this moment I'm mainly looking for sources/types of information that I may collect, in order to produce a relevant clustering analysis. More to come.

## License

The MIT License (MIT)

Copyright (c) 2014 Diogo Teixeira

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

© 2014 Diogo Teixeira. This code is distributed under the MIT license.
