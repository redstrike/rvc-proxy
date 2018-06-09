#!/usr/bin/perl -w
#
# Copyright 2018 Wandertech LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
no strict 'refs';

our $debug = 0;

# A list of shade and awning commands. 'd' and 'n' indicate day or night shade IDs. Where a
# single value is present, a DC_DIMMER_COMMAND is used to toggle the shade. Where individual
# up ('u') and down ('d') values are present, a pair of WINDOW_SHADE_COMMANDs are used.
#
# See notes at bottom of file for conversion from old (pre-2.2.1) values to new (2.2.1+ values).
our %mappings=(
  0  => {'day' => 0,                                          'night' => {'up' => [ 13,  15], 'down' => [ 15,  13]}},
  1  => {'day' => {'up' => [ 77,  78], 'down' => [ 78,  77]}, 'night' => {'up' => [ 79,  80], 'down' => [ 80,  79]}},
  2  => {'day' => {'up' => [ 81,  82], 'down' => [ 82,  81]}, 'night' => {'up' => [ 81,  82], 'down' => [ 82,  81]}},
  3  => {'day' => {'up' => [ 97,  98], 'down' => [ 98,  97]}, 'night' => {'up' => [ 99, 100], 'down' => [100,  99]}},
  4  => {'day' => 0,                                          'night' => {'up' => [101, 102], 'down' => [102, 101]}},
  5  => {'day' => {'up' => [122, 121], 'down' => [121, 122]}, 'night' => {'up' => [122, 121], 'down' => [121, 122]}},
  6  => {'day' => 1,  'night' => 2},
  7  => {'day' => 3,  'night' => 4},
  8  => {'day' => 5,  'night' => 6},
  9  => {'day' => 7,  'night' => 8},
  10 => {'day' => 9,  'night' => 10},
  11 => {'day' => 11, 'night' => 12},
  12 => {'day' => 13, 'night' => 14},
  13 => {'day' => 15, 'night' => 16},
  14 => {'day' => 17, 'night' => 18},
  15 => {'day' => 19, 'night' => 20},
  16 => {'day' => 21, 'night' => 22},
  17 => {'day' => 0,  'night' => 23},
  18 => {'day' => {'up' => [ 18,  17], 'down' => [ 17,  18]}, 'night' => 0},
  19 => {'day' => {'up' => [124, 123], 'down' => [123, 124]}, 'night' => {'up' => [124, 123], 'down' => [123, 124]}},
  # Special shades for customer who added control module to his 2015 Allegro Bus 45 LP
  90 => {'day' => 18, 'night' => 19},  # Windshield
  91 => {'day' => 0,  'night' => 17},  # Passenger Seat
  92 => {'day' => 0,  'night' => 20},  # Driver Seat (pins swapped, up=down)
);

# Up/down options
our %ts=(
  'day'=>1, 'night'=>1
);

# Direction commands
our %ds = (
  'up' => 69, 'down' => 133
);

if ( scalar(@ARGV) < 4 ) {
  print "ERR: Insufficient command line data provided.\n";
  usage();
}

if(!exists($ts{$ARGV[1]})) {
  print "ERR: Shade Type does not exist.  Please see Type list below.\n";
  usage();
}

if(!exists($ds{$ARGV[2]})) {
  print "ERR: Direction not allowed.  Please see Direction list below.\n";
  usage();
}

if(!exists($mappings{$ARGV[3]})) {
  print "ERR: Shade Location does not exist.  Please see Location list below.\n";
  usage();
}

my ($year, $type, $dir) = (shift, shift, shift);

foreach my $loc (@ARGV) {
  shade($loc, $type, $dir);
}

exit;


sub shade {
  my ($loc,$type,$dir) = @_;
  our %ds;
  our %mappings;
  my ($prio,$dgnhi,$dgnlo,$srcAD)=(6,'1FE','DF',96);

  if (ref($mappings{$loc}{$type}) eq 'HASH') {
    $dgnlo='DB';
    my $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
    my $hexCanId=sprintf("%08X",oct("0b$binCanId"));

    # Stop the 'Anti' Location
    my $hexData=sprintf("%02XFFC8%02X%02X00FFFF",$mappings{$loc}{$type}{$dir}[1],3,0);
    system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);

    # Engage the Location
    $hexData=sprintf("%02XFFC8%02X%02X00FFFF",$mappings{$loc}{$type}{$dir}[0],5,30);
    system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);

  } else {
    # Don't make an attempt if the shade ID is 0 (e.g. missing day shade).
    if ($mappings{$loc}{$type} > 0) {

      # 2018 uses reversed directions and different IDs. Also, customer with custom
      # shades on 2015 Bus accidentally swapped directions on his custom shade #92.
      if ($year >= 2018 or $loc == 92) {
        %ds = ('up' => 133, 'down' => 69);
      }

      my $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
      my $hexCanId=sprintf("%08X",oct("0b$binCanId"));
      my $hexData=sprintf("%02XFFC8%02X%02X00FFFF",$mappings{$loc}{$type},$ds{$dir},30);

      system('cansend can0 '.$hexCanId."#".$hexData) if(!$debug);
      print 'cansend can0 '.$hexCanId."#".$hexData."\n" if($debug);
    }
  }
}

sub usage {
  print "Usage: \n";
  print "\t$0 <year> <type> <direction> <location> ...\n";
  print "\n\t<type> is required and one of:\n";
  print "\t\tday, night\n";
  print "\n\t<direction> is required and one of:\n";
  print "\t\tup, down\n";
  print "\n\t<location> is required and one or more of:\n\t\t";
  foreach my $key ( sort {$a <=> $b} keys %mappings ) {
    print "$key "
  }
  print "\n";
  exit(1);
}
