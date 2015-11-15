#!/usr/bin/perl

#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of the GNU General Public License
#       as published by the Free Software Foundation; either version
#       2 of the License, or (at your option) any later version.
#
#       Authors : Stef Coene (stef.coene@docum.orgt)
#                 http://www.docum.org

# This is an adapter version of monitor.pl.  I created this script to monitor the htb tokens and ctokens.

use Time::HiRes qw(gettimeofday usleep);
$arg{sleep} = "3000000" ;	# milli seconds between readings
$arg{dev} = "eth0" ;

foreach my $arg (@ARGV) {
  @split = split ( "=", $arg) ;
  if ( $split[1] eq "" ) {
     print "Error : argument $arg ignored\n  Enter to continue ... " ;
     <STDIN>;
  }
  $arg{$split[0]} = $split[1] ;
}

system ("rm /tmp/tc_monitor.log 2>/dev/null" ) ;

main () ;

sub main {
  $clear = `clear` ;
  print $clear ;
  my %acc_vorige = get_counters () ;
  my %acc_start = %acc_vorige ;
  @start = gettimeofday () ;
  @old_time = gettimeofday () ;
  $time = 0 ;
format STDOUT_TOP =
Classid   tokens   ctokens bytes  speed
------------------------------------------
.
format STDOUT =
@<<<<<<<< @<<<<<<<<@<<<<<< @<<<<< @<<<<<<<
$classid  $tokens  $ctokens $Sent  $speed
.

while (1) {
	my %acc = get_counters () ;
	@time = gettimeofday () ;

	my $diff_time = ( ($time[0]-$old_time[0]) + ($time[1]-$old_time[1])/1000000 );
	my $diff_start = ( ($time[0]-$start[0]) + ($time[1]-$start[1])/1000000 );
	@old_time = @time ;

	open (FILE, ">>/tmp/tc_monitor.log" ) ;
	foreach $key (keys(%acc)) {
		$classid = $key;
		$tokens = $acc{$key}{tokens} ;
		$ctokens = $acc{$key}{ctokens} ;
		$Sent{$key} = $acc{$key}{Sent} - $acc_vorige{$key}{Sent} ;
		$speed = $Sent{$key} / $diff_time ;
		$speed = speed ("$speed") ;
		$Sent = $Sent{$key} ;
		write ;
		print FILE "$diff_start " ;
		print FILE "$acc{$key}{bytes} " ;
		print FILE "$acc{$key}{packets} " ;
		print FILE "$speed " ;
		print FILE "$acc{$key}{tokens} " ;
		print FILE "$acc{$key}{ctokens} " ;

		print FILE "\n" ;
	}
	%acc_vorige = %acc ;
	print "\n" ;
	close FILE ;
} }

sub get_counters {
	my %ACC ;
	my @class = `tc -s -d class show dev $arg{dev}` ; # Get all class info

	foreach my $ele (@class) {
		chomp ($ele) ;
		my @temp = split(" ",$ele) ;
		my $i = 0 ;
		foreach my $temp (@temp) {
			$i ++ ;
			if ( $temp eq "htb" ) {
				$classid = $temp[$i] ;
			} elsif ( $temp =~ /\d/ ) {
				#print "classid $classid $name $temp\n" ;
				$ACC{$classid}{$name} = $temp ;
			} else {
				$temp =~ s/://g ;
				$temp =~ s/\(//g ;
				$name = $temp ;
			}
		}
	}
	usleep ($arg{sleep}) ;
	return  %ACC ;
}

sub speed {
  my $kb = $_[0] / "1024" ;
  @kb = split ( '\.', $kb) ;
  @b = split ("", $kb[1]) ;
  if ( $b[0] == "" ) { $b[0] = "0" ; }
  if ( $b[1] == "" ) { $b[1] = "0" ; }
  if ( $b[2] == "" ) { $b[2] = "0" ; }

  if ( $kb[0] >= "1000" ) { $ret = $kb[0] . "  KB/s" ; }
  elsif ( $kb[0] >= "100" ) {
    $ret = $kb[0] . "." ;
    $ret .= $b[0] . " KB/s" ; }
  elsif ( $kb[0] >= "10" ) {
    $ret = $kb[0] . "." ;
    $ret .= $b[0] . $b[1] . " KB/s" ; }
  else {
    $ret = $kb[0] . "." ;
    $ret .= $b[0] . $b[1] . $b[2] . " KB/s" ; }
  return "$ret" ;
}

