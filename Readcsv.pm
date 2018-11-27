package Up::Model::Readcsv;
#
#   A modulino that reads in a CSV file and insert data into the RDBMS
#
use strict; use warnings; use utf8;
use Perl6::Say;
use Carp 'croak';
use English;
our $VERSION = '1.00';
use Try::Tiny;
use Ouch;
use lib 'lib';
use DBIx::Class::Storage::TxnScopeGuard;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);
use File::Basename;

use Up::Schema;
use MyConfig 'GetDSNinfo';

use Text::CSV;
use open ':encoding(UTF-8)'; # I want my Unicode


# is the file called as a program or a module subroutine???
script() if not caller();


# validate arguments to program and call the main body
sub script {
#   say 'called as script';

   my $filename;
   my $help=0;

   GetOptions ( "file|f=s" => \$filename,    
                "help|h"   => \$help)
      or croak("Error in command line arguments");

   if ( ($help) or (not defined $filename) ) {
      print STDOUT <<EOM;

      Usage Readcsv.pm [-h] [-f file ]
        -h: this help message
        -f: CSV file to be processed

      example: Readcsv.pm -f aaa.csv
EOM
      exit 0;
   }

   if (not (-e $filename)) {
      croak "file: '$filename' , does not exist";
   }

   my ($dsn,$u,$p,$extra) = MyConfig->GetDSNinfo();
   my $db  = Up::Schema->connect($dsn,$u,$p,$extra);

   mymain($filename, $db);
   exit 0;
}


# file used as a module with subroutine 'perform'
sub perform {
#   say 'perform';
   my ($file, $db) = @_;
   mymain($file, $db);
   return 1;
}


# main body of the program whether called as a program or a module method
sub mymain {
#   say 'mymain';
   my ($fn, $dbh) = @_;
   my (@rows, @columns, $guard);
   try {
      # should set binary attribute.
      my $csv = Text::CSV->new ( { binary => 1 } )  
                  or ouch 100, 'Cannot use CSV: '. Text::CSV->error_diag();

#      open my $fh, "<:encoding(utf8)", $fn  or ouch 404, "$fn: $!";
      open my $fh, '<', $fn  or ouch 404, "$fn: $!";


      $guard = $dbh->txn_scope_guard;   # BEGIN_TRANSACTION

      # Enter master header
      my($filename, $dirs, $suffix) = fileparse( $fn );
      my $dataset_rs = $dbh->resultset('Dataset')->create( { file => $filename, });
      my $file_id = $dataset_rs->file_id;
#      say $file_id;

      # Enter header for detail(s)
      my $datasheet_rs = $dbh->resultset('Datasheet') ->create({ file_id    => $file_id,
                                                                 sheet_indx => 1, 
                                                                 sheet_name => 'Sheet1', });
      my $sheet_id  = $datasheet_rs->sheet_id;

      # Enter detail(s)
      my $data_rs = $dbh->resultset('Data');
      while ( my $row = $csv->getline( $fh ) ) {
          while (my ($col_indx, $field) = each(@$row) ) {
              $data_rs->create({ file_id  => $file_id,  sheet_id => $sheet_id,
                                 row_indx => $NR-1,       col_indx => $col_indx,
                                 field    => $field, });
          }
      }
      $csv->eof or ouch 101, $csv->error_diag();
      close $fh;
   }
   catch {
      croak $_ ; # rethrow
   };

   $guard->commit;   # END_TRANSACTION


   return;
}

1;
__END__

=head1 NAME

Readcsv  

A modulino that reads in a CSV file and insert data into the RDBMS


=head1 VERSION

This document describes Readcsv version 0.0.1


=head1 SYNOPSIS

       use Up::Model::Readcsv;
       Up::Model::Readcsv::perform( file, database handle );
   OR
       $ perl lib/Up/Model/Readscv.pm -f file.csv

=head1 DESCRIPTION


  Read a CSV file and place the data into the Upload project's RDBMS
  
  layout.

  CREATE TABLE dataset (
       file_id INTEGER PRIMARY KEY AUTOINCREMENT,
       file    TEXT not null,
       transaction_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       unique (file_id)

  CREATE TABLE datasheet (
       sheet_id   INTEGER PRIMARY KEY AUTOINCREMENT,
       file_id    INTEGER not null references dataset(file_id),
       sheet_indx INTEGER not null,
       sheet_name TEXT    not null,
       unique (sheet_id),
       unique (file_id, sheet_indx)

  CREATE TABLE data (
       row_id INTEGER PRIMARY KEY AUTOINCREMENT,
       file_id    INTEGER not null references dataset(file_id),
       sheet_id   INTEGER not null references datasheet(sheet_id),
       row_indx   INTEGER not null,
       col_indx   INTEGER not null,
       field      TEXT    not null,
       unique (row_id),
       unique (file_id, sheet_id, row_indx, col_indx)


=cut
