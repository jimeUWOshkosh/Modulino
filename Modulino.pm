package Modulino;
use strict; use warnings; use utf8;
use Perl6::Say;
our $VERSION = '1.00';

# is the file called as a program or a module subroutine???
script() if not caller();


# validate arguments to program and call the main body
sub script {
   say 'called as script';


#   GetOptions ( ... ) or croak("Error in command line arguments");

#   my $db  = Up::Schema->connect($dsn,$u,$p,$extra);

   my ($filename, $db);
   mymain($filename, $db);
   exit 0;
}


# file used as a module with subroutine 'perform'
sub perform {
   say 'perform';
   my ($file, $db) = @_;
   mymain($file, $db);
   return 1;
}


# main body of the program whether called as a program or a module method
sub mymain {
   say 'mymain';
   return;
}

1;
