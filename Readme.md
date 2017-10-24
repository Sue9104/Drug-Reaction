# NAME

Drug::Reaction - Drug Reaction Analysis in 9800

# VERSION

version 1.001

# SYNOPSIS

    use Drug::Reaction;
    my $instance = Drug::Reaction->new(
      para => "./para",
      step => "1,2",
      genotype => "sample1.csv",
      gender => "gender.csv",
      outdir => "drug-reaction_results"
    );
    $instance->drug_reaction_main;
    
    or
    
    drug_reaction --help

# ATTRIBUTES

## genotype

affy genotype csv file or dir included csv files,
csv file formate as "rs\_id,chemical\_id,pharmgkb\_id,Plate ID,Sample ID,Call Code"

## gender

gender csv file, formate as "sample\_id,gender", gender must be chinese

## para

share directory, included essential files for analysization

init db

- pharmgkb-alleles-description-20170810.csv
- pharmgkb-alleles.csv
- pharmgkb-annotations.csv
- pharmgkb-chemicals-summary.csv
- pharmgkb-chemicals.csv
- pharmgkb-evidences.csv

analysis

- chemical\_info.csv

## step

- 0: database initialize
- 1: run the drug-reaction process, default is 1
- 2: put the results to database
- 1,2: run step 1 and step 2

## db\_url

drug-reaction database url, default is 'postgres://postgres:123456@192.168.1.205:5439/pharmgkb'

## outdir

analysis output directory

# METHODS

## init\_db

drug\_reaction database initialize, must provide para directory

## drug\_reaction

drug reaction analysis, must provide genotype and gender

## upload\_to\_db

execute sql within db\_url

## drug\_reaction\_main

drug reaction analysis pipeline, has three steps:

- 0 initialize db
- 1 drug-reaction analysis
- 2 upload results to database

# SEE ALSO

# AUTHOR

Su Min <sumin@cheerlandgroup.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by CheerLand Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
