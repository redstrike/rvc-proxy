#!/usr/bin/perl -w
#
# Copyright Wandertech LLC
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
use Net::MQTT::Simple "localhost";
use YAML::Tiny;
use JSON;
use Switch;

my $yaml = YAML::Tiny->read('./rvc-spec.yml');
our $decoders = $yaml->[0];

open FILE,'candump -ta can0 |' or die("Cannot start candump " . $! ."\n");

# candump output looks like:
#
# (1550629697.810979)  can0  19FFD442   [8]  01 02 F7 FF FF FF FF FF

while (my $line = <FILE>) {
  chomp($line);
  my @line_parts = split(' ', $line);
  my $pkttime  = $line_parts[0];
  $pkttime     =~ s/[^0-9\.]//g;
  my $binCanId = sprintf("%b", hex($line_parts[2]));
  my $prio     = sprintf(  "%X", oct("0b".substr( $binCanId,  0,  3)));
  my $dgn      = sprintf("%05X", oct("0b".substr( $binCanId,  4, 17)));
  my $srcAD    = sprintf("%02X", oct("0b".substr( $binCanId, 21,  8)));
  my $pckts    = $line_parts[3];
  $pckts       =~ s/[^0-9]//g;

  my $data     = '';
  for (my $i = 4; $i < scalar(@line_parts); $i++) {
    $data .= $line_parts[$i];
  }
  our $char = "$pkttime,$prio,$dgn,$srcAD,$pckts,$data";
  processPacket();
}
close FILE;
exit;


sub processPacket {
	our $char;

	if ($char) {
		$char =~ s/\xd//g;
		our ($pkttime, $prio, $dgn, $src, $pkts, $data) = split(',', $char);
		our $partsec = ($pkttime - int($pkttime)) * 100000;
		our $dgnHi = substr($dgn,0,3) if (defined($dgn));
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($pkttime);
    $year += 1900;
    $mon++;

    my %result = decode($dgn, $data);
    if (%result) {
      $result{timestamp} = $pkttime;
      my $result_json = JSON->new->utf8->canonical->encode(\%result);
      my $topic = "RVC/$result{name}";
      $topic .= '/' . $result{instance} if (defined($result{instance}));
      publish $topic => $result_json;
      printf("%4d-%02d-%02d %02d:%02d:%02d.%05d %s %s %s %s\n", $year, $mon, $mday, $hour, $min, $sec, $partsec, $src, $data, $topic, $result_json);
    }
	}
}


# Params:
#   DGN (hex string)
#   Data (hex string)
sub decode() {
  my $dgn  = shift(@_);
  my $data = shift(@_);
  my %result;
  our $decoders;

  # Locate the decoder for this DGN
  my $decoder = $decoders->{$dgn};

  $result{dgn} = $dgn;
  $result{data} = $data;
  $result{name} = "UNKNOWN-$dgn";
  return %result unless defined $decoder;

  $result{name} = $decoder->{name};

  my @parameters;

  # If this decoder has an alias specified, load the alias's parameters first.
  # If needed, parameters can also be overridden within the base decoder.
  push(@parameters, @{$decoders->{$decoder->{alias}}->{parameters}}) if ($decoder->{alias});

  # Add the parameters from the specified decoder
  push(@parameters, @{$decoder->{parameters}}) if ($decoder->{parameters});

  # Loop through each parameter for the DGN and decode it.
  my $parameter_count = 0;
  #foreach my $parameter (@{$decoder->{parameters}}) {
  foreach my $parameter (@parameters) {
    my $name = $parameter->{name};
    my $type = $parameter->{type} // 'uint';
    my $unit = $parameter->{unit};
    my $values = $parameter->{values};

    # Get the specified byte or byte range, in hex
    my $bytes = get_bytes($data, $parameter->{byte});

    # Store the decoded value in decimal
    my $value = hex($bytes);

    # Get the specified bit or bit range, if applicable
    if (defined $parameter->{bit}) {
      my $bits = get_bits($bytes, $parameter->{bit});
      $value = $bits;

      # Convert from binary to decimal if the data type requires it
      if (substr($type, 0, 4) eq 'uint') {
        $value = oct('0b' . $bits);
      }
    }

    # Convert units, such as %, V, A, ºC
    if (defined $unit) {
      $value = convert_unit($value, $unit, $type);
    }

    $result{$name} = $value;

    # Decode value definitions, if provided.
    my $value_def = $value;
    if ($values) {
      $value_def = 'Undefined';
      $value_def = $values->{$value} if ($values->{$value});
      $result{"$name definition"} = $value_def;
    }

    $parameter_count++;
  }

  if ($parameter_count == 0) {
    $result{'DECODER PENDING'} = 1;
  }

  return %result;
}


# Given a hex string (e.g. "020064C524C52400") and a byte range (e.g. "2" or
# "2-3"), return the appropriate hex string for those bytes (e.g. "6400"). Per
# RV-C spec, "data consisting of two or more bytes shall be transmitted least
# significant byte first." Thus, the byte order must be swapped if a range is
# requested.
sub get_bytes() {
  my $data = shift(@_);
  my $byterange = shift(@_);
  my $bytes = "";

  my ($start_byte, $end_byte) = split(/-/, $byterange);
  $end_byte = $start_byte if !defined $end_byte;

  my $sub_bytes = substr($data, $start_byte * 2, ($end_byte - $start_byte + 1) * 2);
  $bytes = join '', reverse split /(..)/, $sub_bytes;

  # Alternate method using for loop:
  #for (my $i = $end_byte; $i >= $start_byte; $i--) {
    #$bytes .= substr($data, $i * 2, 2);
  #}

  return $bytes;
}


# Given a hex string (e.g. "64C5") and a bit range (e.g. "3-4"), return the
# requested binary representation (e.g. "1011").
sub get_bits() {
  my $bytes = shift(@_);
  my $bitrange = shift(@_);
  my $bits = hex2bin($bytes);

  my ($start_bit, $end_bit) = split(/-/, $bitrange);
  $end_bit = $start_bit if !defined $end_bit;

  my $sub_bits = substr($bits, 7 - $end_bit, $end_bit - $start_bit + 1);

  return $sub_bits;
}


# Convert a single hex byte (e.g. "F7") to an 8-character binary string.
# https://www.nntp.perl.org/group/perl.beginners/2003/01/msg40076.html
sub hex2bin() {
  my $hex = shift(@_);
  return unpack("B8", pack("C", hex $hex));
}


# For a given unit (e.g. "V") and datatype (e.g. "uint16"), compute and
# return the actual value based on RV-C table 5.3.
sub convert_unit() {
  my $value = shift(@_);
  my $unit = shift(@_);
  my $type = shift(@_);

  my $new_value = 'n/a';

  switch (lc($unit)) {
    case 'pct' {
      $new_value = $value/2 if ($value != 255);
    }
    case 'deg c' {
      switch ($type) {
        case 'uint8'  { $new_value = $value - 40 unless ($value == 255) }
        case 'uint16' { $new_value = int(10 * ($value * 0.03125 - 273)) / 10 unless ($value == 65535) }
      }
    }
    case "v" {
      switch ($type) {
        case 'uint8'  { $new_value = $value unless ($value == 255) }
        case 'uint16' { $new_value = int(10 * $value * 0.05) / 10 unless ($value == 65535) }
      }
    }
    case "a" {
      switch ($type) {
        case 'uint8'  { $new_value = $value }
        case 'uint16' { $new_value = int(10 * ($value * 0.05 - 1600)) / 10 unless ($value == 255) }
        case 'uint32' { $new_value = int(100 * ($value * 0.001 - 2000000)) / 100 unless $value == 4294967295 }
      }
    }
    case "bitmap" {
      $new_value = sprintf('%08b', $value);
    }
  }

  return $new_value;
}
