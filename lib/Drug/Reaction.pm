package Drug::Reaction;
# ABSTRACT: Drug Reaction Analysis in 9800

use Modern::Perl;
use Data::Dumper;
use IO::All -utf8;
use Cwd 'abs_path';
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);

use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;
use Carp 'croak';
use namespace::autoclean;


has 'genotype' => (
  is       => 'ro',
  isa      => 'Str',
);


has 'gender' => (
  is       => 'ro',
  isa      => 'Str',
);

has 'para' => (
  is       => 'ro',
  isa      => 'Str',
  default  => "$Bin/para"
);

has 'step' => (
  is       => 'rw',
  isa      => 'Str',
  default => 1
);

has 'db_url' => (
  is       => 'rw',
  isa      => 'Str',
  default  => 'postgres://postgres:123456@192.168.1.205:5439/pharmgkb'
);

has 'outdir' => (
  is       => 'ro',
  isa      => 'Str'
);
method init_db( $init_sql! ){
  my $para = abs_path( $self->para );
  if (!-d $para ){
    croak "Error: Must provide para directory for init drug-reaction db";
  }else {
    my $cmd = qq(
\\copy allele_description from '$para/pharmgkb-alleles-description-20170810.csv' with csv header;
\\copy alleles from '$para/pharmgkb-alleles.csv' with csv header;
\\copy annotations from '$para/pharmgkb-annotations.csv' with csv header;
\\copy chemical_description from '$para/pharmgkb-chemicals-summary.csv' with csv header;
\\copy chemicals from '$para/pharmgkb-chemicals.csv' with csv header;
\\copy evidences from '$para/pharmgkb-evidences.csv' with csv header;
REFRESH MATERIALIZED VIEW chemical_infos;
);
    my $out = io($init_sql);
    $out->print($cmd);
  }
}

method drug_analysis( $outdir! ){
  my $genotype = abs_path( $self->genotype );
  my $gender = abs_path( $self->gender );
  my $para = abs_path( $self->para );

  if ( !$genotype || !-d $para || !-f $gender ){
    croak "Error: Must provide genotype file/dir and gender file";
  }else{
    my $tmp = "$outdir/drug_results"; mkdir $tmp unless(-d $tmp);
    my @files = (-f $genotype) ? ($genotype) : glob "$genotype/*csv";
    my $cmd;
    for my $f ( @files ){
      my $name = basename($f);
      my $analysis_cmd = qq(xsv join 3 $para/chemical_info.csv 4 $f |awk -F, '{printf "%s,%s,%s,%s,%s,%s\\n", \$3,\$1,\$2,\$4,\$5,\$8}' > $tmp/$name ) ;
      system($analysis_cmd);
      $cmd .= qq(\\copy sample_chemical_genotype_fast from '$tmp/$name' with csv header;) . "\n";
    }
    
    $cmd .= qq(
\\copy gender from '$gender' with csv header;
REFRESH MATERIALIZED VIEW final_results_fast;
);
    io("$outdir/upload_drug-reaction.sql")->print($cmd);
  }

}

method upload_to_db ( $sql! ){
  my $db_url = $self->db_url;
  my $cmd = qq(psql $db_url -f $sql);
  system($cmd);
}

method drug_reaction_main(){
  say Dumper($self);
  my $outdir = abs_path($self->outdir); mkdir $outdir unless (-d $outdir);
  my @steps = split /,/, $self->step;
  for my $step ( @steps ){
    if ( $step == 0 ){
      my $init_sql = "$outdir/init_db.sql";
      $self->init_db( $init_sql );
      $self->upload_to_db( $init_sql );
    }elsif ( $step == 1){
      $self->drug_analysis( $outdir );
    }elsif ( $step == 2 ){
      $self->upload_to_db("$outdir/upload_drug-reaction.sql");
    }
  }
}
no Moose;
__PACKAGE__->meta->make_immutable;
1

__END__

=pod

=encoding UTF-8

=head1 NAME

Drug::Reaction - Drug Reaction Analysis in 9800

=head1 VERSION

version 0.001

=head1 SYNOPSIS

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

=head1 ATTRIBUTES

=head2 genotype

affy genotype csv file or dir included csv files,
csv file formate as "rs_id,chemical_id,pharmgkb_id,Plate ID,Sample ID,Call Code"

=head2 gender

gender csv file, formate as "sample_id,gender", gender must be chinese

=head2 para

share directory, included essential files for analysization

init db

=over 4

=item pharmgkb-alleles-description-20170810.csv

=item pharmgkb-alleles.csv

=item pharmgkb-annotations.csv

=item pharmgkb-chemicals-summary.csv

=item pharmgkb-chemicals.csv

=item pharmgkb-evidences.csv

=back

analysis

=over 4

=item chemical_info.csv

=back

=head2 step

=over 4

=item 0: database initialize

=item 1: run the drug-reaction process, default is 1

=item 2: put the results to database

=item 1,2: run step 1 and step 2

=back

=head2 db_url

drug-reaction database url, default is 'postgres://postgres:123456@192.168.1.205:5439/pharmgkb'

=head2 outdir

analysis output directory

=head1 METHODS

=head2 init_db

drug_reaction database initialize, must provide para directory

=head2 drug_reaction

drug reaction analysis, must provide genotype and gender

=head2 upload_to_db

execute sql within db_url

=head2 drug_reaction_main

drug reaction analysis pipeline, has three steps:

=over 4

=item 0 initialize db

=item 1 drug-reaction analysis

=item 2 upload results to database

=back

=head1 SEE ALSO

=head1 AUTHOR

Su Min <sumin@cheerlandgroup.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by CheerLand Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
