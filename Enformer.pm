=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2023] EMBL-European Bioinformatics Institute
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
     http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=head1 CONTACT
 Ensembl <http://www.ensembl.org/info/about/contact/index.html>
=cut

=head1 NAME
 Enformer

=head1 SYNOPSIS
 
 mv Enformer.pm ~/.vep/Plugins
 ./vep -i variations.vcf --plugin Enformer,file=Enformer_grch37.vcf.gz


=head1 DESCRIPTION
 This is a plugin for the Ensembl Variant Effect Predictor (VEP) that adds pre-calculated scores from Enformer.

 This Plugin is available for GRCh37 and GRCh38
 
 Please cite the Enformer publication alongside the VEP if you use this resource:
 https://www.nature.com/articles/s41592-021-01252-x

 Enformer scores can be downloaded from https://ftp.ensembl.org/pub/current_variation/Enformer for GRCh37 and GRCh38.

 The tabix utility must be installed in your path to use this plugin.
 Check https://github.com/samtools/htslib.git for instructions.


=cut

package Enformer;

use strict;
use warnings; 

use Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin;
use base qw(Bio::EnsEMBL::Variation::Utils::BaseVepTabixPlugin);

sub new {
  my $class = shift;
  
  my $self = $class->SUPER::new(@_);

  $self->expand_left(0);
  $self->expand_right(0);
  $self->get_user_params();
  
  my $params = $self->params_to_hash();
  
  my $file;
  if (!keys %$params) {
    $file = $self->params->[0];
    $params->{file} = $file;
  } else {
    $file = $params->{file};
  } 

  $self->add_file($file);
  
  my $assembly = $self->{config}->{assembly};

  return $self;

}

sub feature_types {
  return ['Transcript'];

}

sub get_header_info {
  return { Enformer => "Prediction tool to accurately identify variant impact on gene expression" };
}

sub run{
  my ($self, $tva) = @_;
  
  my $vf = $tva->variation_feature;
  my $allele = $tva->variation_feature_seq;
  return {} unless $allele =~ /^[ACGT]$/;
  

  my ($vf_start, $vf_end) = ($vf->{start}, $vf->{end});
  ($vf_start, $vf_end) = ($vf_end, $vf_start) if ($vf_start > $vf_end);

  my ($res) = grep{
    $_->{alt} eq $allele &&
    $_->{start} == $vf_start &&
    $_->{start} == $vf_end
    } @{$self->get_data($vf->{chr}, $vf_start, $vf_end)};
    
  return $res ? $res->{result} : {};
}


sub parse_data {
  my ($self, $line) = @_;
  my ($chr_data, $start, $snp, $ref, $alt, $qual, $filter, $data) = split("\t", $line);
  
  my ($chr) = $chr_data =~ /(\d+)/; # this is because the chromosome is chr1 etc, to retrieve just the 1
  return {
    chr => $chr,
    start => $start,
    ref => $ref,
    alt => $alt,
    result => {
      Enformer => $data
    }
  };
}

sub get_start {
  return $_[1]->{start};
}

sub get_end {
  return $_[1]->{end};
}

1;