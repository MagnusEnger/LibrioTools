#!/opt/local/bin/perl -w

# line2iso.pl
# Copyright 2009 Magnus Enger

# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this file; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

use MARC::File::USMARC;
use MARC::File::XML;
use MARC::Record;
use Getopt::Long;
use File::Slurp;
use strict;

# Options
my $file = '';
my $xml = '';
GetOptions (
  'i|input=s' => \$file, 
  'x|xml' => \$xml 
);

# Usage
if (!$file) {
  print "
This will turn a file of MARC-records in line format into ISO2709 or MARCXML.

Usage:
  ./line2iso.pl -i in.txt > out.mrc
  ./line2iso.pl -i in.txt -x > out.xml

Options:
  -i --input = Input file
  -x --xml = Outout as MARCXML

See also:
  yaz-marcdump http://www.indexdata.com/yaz/doc/yaz-marcdump.html

";
exit;
}

# Check that the file exists
if (!-e $file) {
  print "The file $file does not exist...\n";
  exit;
}

# Slurp file
my @lines = read_file($file);

# Start an empty record
my $record = MARC::Record->new();

# Counter for records
my $num = 0;
# Make chomp() behave 
$/ = "\r\n";

foreach my $line (@lines) {
	
  chomp($line);
  
  # For some reason some lines begin with "**"
  # These seem to be errors of some kind, so we skip them
  if ($line =~ /^\*\*/) {
  	next;
  }

  if ($line =~ /\^/) {
  	
  	# print "\nEND OF RECORD $num";
  	
  	# Output the record
  	if ($xml) {
  	  print $record->as_xml(), "\n";
  	} else {
  	  print $record->as_usmarc(), "\n";
  	}
  	
  	# Start over with an empty record
  	$record = MARC::Record->new();
  	
  	# Count the records
  	$num++;
  	
  	# Process the next line
  	next;
  	
  }
  
  # Some lines are just e.g. "*300 ", we skip these
  if (length($line) < 6) {
  	next;
  }
  
  my $field = substr $line, 1, 3;
  # print "$field\n";
  
  if ($field ne "000" && $field ne "001" && $field ne "007" && $field ne "008") {
  	
    my $ind1  = substr $line, 4, 1;
    if ($ind1 eq " ") {
      $ind1 = "";
    }
    my $ind2  = substr $line, 5, 1;
    if ($ind2 eq " ") {
      $ind2 = "";
    }
    
    my $subs  = substr $line, 7;
    my @subfields = split(/\$/, $subs);
    my $subfield_count = 0;
    my $newfield = "";
    
    foreach my $subfield (@subfields) {
      
      # print "$subfield\n";
      
      my $index = substr $subfield, 0, 1;
      my $value = substr $subfield, 1;
      
      # print "$index = $value\n";
      
      if ($subfield_count == 0) {
        $newfield = MARC::Field->new($field, $ind1, $ind2, $index => $value);
      } else {
        $newfield->add_subfields($index, $value);
      }
      
      # if ($field eq "099" && $index eq "a") {
      # 	print "$value ";
      # }
      
      $subfield_count++;
      
    }
    
    $record->append_fields($newfield);
    
  } else {
  	
  	my $value = substr $line, 4;
    my $field = MARC::Field->new($field, $value);
    $record->append_fields($field);
  
  }
  
}

# print "\n$num records processed\n";