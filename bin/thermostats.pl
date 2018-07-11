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

# Thermostat control was added in the 2018 Phaeton and above.

use strict;
no strict 'refs';
use Switch

our $debug = 0;

our %commands = (
  'off' => 'Off',
  'cool' => 'A/C On',
  'heat' => 'Heat On',
  'low' => 'Fan Low',
  'high' => 'Fan High',
  'auto' => 'Fan Auto',
  'up' => 'Temp Up',
  'down' => 'Temp Down',
  'set' => 'Set Temp To...',
);

our %thermostat_commands = (
  'off'  => 'C0FFFFFFFFFFFF',
  'cool' => 'C1FFFFFFFFFFFF',
  'heat' => 'C2FFFFFFFFFFFF',
  'low'  => 'DF64FFFFFFFFFF',
  'high' => 'DFC8FFFFFFFFFF',
  'auto' => 'CFFFFFFFFFFFFF',
  'low_fanonly'  => 'D464FFFFFFFFFF',
  'high_fanonly' => 'D4C8FFFFFFFFFF',
  'auto_fanonly' => 'C0FFFFFFFFFFFF',
  'up'   => 'FFFFFFFFFAFFFF',
  'down' => 'FFFFFFFFF9FFFF',
);

if (scalar(@ARGV) < 2) {
	print "ERROR: Too few command line arguments provided.\n";
	usage();
}

our $instance = $ARGV[0];
if ($instance < 0 or $instance > 6) {
	print "ERROR: Invalid zone specified.\n";
	usage();
}

our $command = $ARGV[1];
if (!exists($commands{$command})) {
	print "ERROR: Invalid command specified.\n";
	usage();
}

# When controlling the fans, slightly different commands need to be sent
# depending on whether the "mode" is already set to something like A/C or
# not.
if (scalar(@ARGV) >= 3) {
  our $current_mode = $ARGV[2];
  if (grep(/^$command$/, ('low', 'high', 'auto')) and grep(/^$current_mode$/, ('off', 'fan'))) {
    $command .= '_fanonly';
  }
}

our ($prio, $dgnhi, $dgnlo, $srcAD) = (6, '1FE', 'F9', 99);

our $binCanId = sprintf("%b0%b%b%b", hex($prio), hex($dgnhi), hex($dgnlo), hex($srcAD));
our $hexCanId = sprintf("%08X", oct("0b$binCanId"));

our $hexData;

# Send THERMOSTAT_COMMAND.
if ($thermostat_commands{$command}) {
  $hexData = sprintf("%02X%s", $instance, $thermostat_commands{$command});
  cansend($hexCanId, $hexData);
}

# Send setpoint commands
if ($command eq 'set') {
  if (exists($ARGV[2])) {
    my $tempRVC = tempF2hex($ARGV[2]);
    $hexData = sprintf("%02XFFFF%s%sFF", $instance, $tempRVC, $tempRVC);
    cansend($hexCanId, $hexData);

    # Also set the furnace setpoints, if available. So far, only zones 0 and 2 (RED)
    # or 2 and 4 (Phaeton+) have furnaces available.
    if ($instance % 2 == 0) {
      $hexData = sprintf("%02XFFFF%s%sFF", $instance + 3, $tempRVC, $tempRVC);
      cansend($hexCanId, $hexData);
    }
  }
}

exit;

# Add 0.999 to perform a ceil() function on the resulting value to prevent
# rounding errors. E.g. 71 F normally translates to 9429.33333 or 24D5 hex.
# However, 24D5 translates back to 70.98125 F, causing the Spyder screen to
# display 70 instead of 71.
sub tempF2hex {
	my ($data)=@_;
	my $hexchars=sprintf("%04X",(((($data-32)*5/9)+273)/0.03125)+0.999);
	my @binarray= $hexchars =~ m/(..?)/sg;
	return $binarray[1].$binarray[0];
}


sub cansend {
  our $debug;
  my ($id, $data) = @_;
  system('cansend can0 ' . $id . "#" . $data) if (!$debug);
  print 'cansend can0 '. $id . "#" . $data . "\n" if ($debug);
}


sub usage {
	print "Usage: \n";
	print "\t$0 <zone> <command>\n";
	print "\n\tZones:\n";
  print "\t\tHighline coaches: 2=Front 3=Mid 4=Rear 5=Front Furnace 6=Rear Furnace\n";
  print "\t\tLowline coaches:  0=Front 1=Mid 2=Rear 3=Front Furnace 4=Rear Furnace\n";
	print "\n\tCommands:\n";
	foreach my $key ( keys %commands ) {
		print "\t\t" . $key . " = " . $commands{$key} . "\n";
	}
	print "\n";
	exit(1);
}
