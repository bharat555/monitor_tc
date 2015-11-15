#!/usr/bin/perl

#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of the GNU General Public License
#       as published by the Free Software Foundation; either version
#       2 of the License, or (at your option) any later version.
#
#       Authors : Stef Coene (stef.coene@docum.org)
#                 http://www.docum.org
#	          Bjarke Johannesen (bjarke@copyparty.dk)
#
# This is a rewritten version of Stef Coenens monitor_tc, into a program that
# displays traffic on the different classes on tc in a top program like fasion.
#
# Version 0.1 Tested and supports HTB
#   Modified to support CBQ instead
#     Bob Toxen (bob@verysecurelinux.com) 11/17/2005
#
# At the top of the display uptime is showen.
#   Dev - Device name where the tc class is
#   Classid - is the class identifier name
#Bob #   Tokens - The tokens of the specific class
#Bob #   Ctokens - is the ctokens of the specific class
#   Rate - the send bytes pr. second that the class it self gives(htb)
#   Interval Speed - Is the bytes/sec messurement in this interval
#   Cumulated Send - Is the amount of data that has been send while this 
#                    program has been running.
#   Total Send - Is the total send amount sence the tc class have been started
#
#   The parent class is highlighted
#
#
# Input parameters:
#
# dev=eth3        for getting tc on device eth3
# dev="eth0 eth3" for a list of devices
# sleep=1000000   the sleeping period between sdreen updates.
# once=yes        display only a single iteration and without escape seq.

#Bob use Time::HiRes qw(gettimeofday usleep);
#Bob $arg{sleep} = "3000000" ;	# milli seconds between readings (3 sec)
#Bob $arg{sleep} = "3" ;	# seconds between readings (3 sec)
$arg{sleep} = "1" ;	# seconds between readings (1 sec)
$arg{dev} = "eth6" ; #default devices to listen to
$arg{once} = "no" ; #Non-zero to do only one

foreach my $arg (@ARGV) {
  @split = split ( "=", $arg) ;
  if ( $split[1] eq "" ) {
     print "Error : argument $arg ignored\n  Enter to continue ... " ;
     <STDIN>;
  }
  $arg{$split[0]} = $split[1] ;
}

#system ("rm /tmp/tc_monitor.log 2>/dev/null" ) ;

main () ;

sub main {
  $clear = `tput clear` ;
  $bold = `tput bold` ;
  $reverse = `tput rev` ;
  $attroff = `tput sgr0 `; 
  if ( $arg{once} eq "no" ) {
	print $clear ;
	print $attroff;
	print "shape dev='ethX ethY' to list specified devices\n";
	print "shape once=yes        to show only once\n";
	print "\n";
	print "Updating...\n"; 
	system ("tput cup 1 0");
  }

  my %acc_vorige = get_counters () ;
  #my %acc_start = %acc_vorige ;
#Bob  @start = gettimeofday () ;
#Bob  @old_time = gettimeofday () ;
  @start = [gettimeofday] ;
  @old_time = [gettimeofday] ;
  $time = 0 ;
#Bob $device $classid  $tokens  $ctokens $Sent  "$speed/s"  $cumsend $send
format STDOUT =
@<<< @<<<<<<<< @<<<<<<<<@<<<<<<<<<< @<<<<<<<< @<<<<<<<<<<<< @<<<<<<<< @<<<<<<<<<<<<<
$device $classid  $prio  "$speed"  $cumsend "$cumspeed" $send $comment
.

if ( $arg{once} eq "yes" ) {
	system ("uptime");
	print "\n";
}
print "                        Interval    Monitor   Monitor       Total\n";
print "Dev  Classid   Priority Speed       Bytes     Speed         Bytes     Comment\n";
print "--------------------------------------------------------------------------------\n";
@invoke_time = `date +%s` ;

$iter = 0 ;

while (1) {
	$iter = $iter + 1 ;
	my %acc = get_counters () ;
	#making more precise messurement of data sent
	%acc_next = %acc ;
	@now_time = `date +%s` ;

#Bob	@time = gettimeofday () ;
#Bob	my $diff_time = ( ($time[0]-$old_time[0]) + ($time[1]-$old_time[1])/1000000 );
	#my $diff_start = ( ($time[0]-$start[0]) + ($time[1]-$start[1])/1000000 );
	@time = `date +%s` ;
#Bob2	my $diff_time = ($time-$old_time);
	my $diff_time = $arg{sleep};
	my $total_time = ($now_time-$invoke_time+1);
	@old_time = @time ;

	#show bling bling
	if ( $arg{once} eq "no" ) {
		system ("tput cup 0 0");
		system ("uptime");
		print "\n";
		system ("tput cup 4 0");
	}

	#open (FILE, ">>/tmp/tc_monitor.log" ) ;

	foreach $key (sort (keys(%acc))) {
		#skaerm output
		$device = $acc{$key}{dev};
		$classid = $key;
		$prio = $acc{$key}{prio} ;
		$tokens = $acc{$key}{tokens} ;
		$ctokens = $acc{$key}{ctokens} ;
		$Sent{$key} = $acc{$key}{Sent} - $acc_vorige{$key}{Sent} ;
		$speed = $Sent{$key} / $diff_time * 8 ;
		if ( $iter == 1 ) {
			$xcumspeed{$key} = 0 ;
		}
		$xcumspeed{$key} += $speed ;
		$speed = convb ("$speed") ;

		$ocumsend{$key}+=$Sent{$key};
		$cumsend= conv ("$ocumsend{$key}");
#Bob broken	$cumspeed= convb ("$cumspeed{$key}" * 8);
		$cumspeed="N/A";
		$cumspeed= convb ("$xcumspeed{$key}" / $iter);

		#$Sent = conv ("$Sent{$key}") ;
		$Sent = conv ( $acc{$key}{rate});
		$send= conv ("$acc{$key}{Sent}");
		$Sent="N/A";
		$send="N/A";

				# Suck comment on meaning of rule from file
		$classsub=`echo -n $classid | sed 's/.*://'`;
		if ( "$classsub" != "" && "$classsub" != "1" ) {
			$todo="/etc/rc.d/cbq/cbq-".$classsub.".".$device."*";
			$comment=`grep "^#C " $todo|sed 's/#C *//'|head -1`;
		} else {
			$comment="";
		}

		#highlight the master classid
		if ( $arg{once} eq "yes" ) {
			$acc{$key}{master} = 0 ;
		}
		if ($acc{$key}{master} == 1) {
			print $bold;
			write;
			print $attroff;
		} else {	
			write ;
		}
		#logfil output
		#print FILE "$diff_start " ;
		#print FILE "$acc{$key}{bytes} " ;
		#print FILE "$acc{$key}{packets} " ;
		#print FILE "$speed " ;
		#print FILE "$acc{$key}{tokens} " ;
		#print FILE "$acc{$key}{ctokens} " ;
		#print FILE "$acc{$key}{Sent} " ;

		#print FILE "\n" ;
	}
	%acc_vorige = %acc_next ;
	#print "\n" ;
	#close FILE ;

			# Bob: if once then exit.
	if ( $arg{once} eq "y" ) {
		$arg{once} = "yes" ;
	}
	if ( $arg{once} eq "yes" ) { #set classid
		exit 0 ;
	}
} }

sub get_counters {
	my %ACC ;
	my @class ; # Get all class info array
	my $first=0; #this is to find the master classid
	my @devices=split (" ",$arg{dev}); #all devices to get tc stats from
	my $ratect=0; # countring sub values of rate

	foreach my $devs (@devices) {
	$first=0;
        @class = `tc -s -d class show dev $devs` ; 
	foreach my $ele (@class) {
		chomp ($ele) ;
		my @temp = split(" ",$ele) ;
		my $i = 0 ;
		foreach my $temp (@temp) {
			$i ++ ;
#Bob			if ( $temp eq "htb" ) { #set classid
			if ( $temp eq "cbq" ) { #set classid
				$classid = $temp[$i] ;	
				#master classid
				if ( $first == 0 ) {
					if ( "$classid" eq "1:" ) {
						$ACC{$classid}{master}=1;
						$first=1;
					}
				}
				else {
					$ACC{$classid}{master}=0;
				}
				#set device name
        			$ACC{$classid}{dev}=$devs;
				$ratect=0;
			} elsif ( $temp eq "Sent" ) { #find sub val of rate
				#print "classid $classid $name $temp\n" ;
				$ratect++;
				$ACC{$classid}{rate} = 0 ;
				$ACC{$classid}{Sent} = $temp[$i] ;
			} elsif ( $temp eq "prio" ) { #find priority
				$ACC{$classid}{prio} = $temp[$i] ;
				$ACC{$classid}{prio} =~ s/\/.*// ;
				$ACC{$classid}{prio} =~ s/no-transmit/N\/A/ ;
				#print "classid $classid prio $ACC{$classid}{prio}\n" ;
			} else { # set key
				$temp =~ s/://g ;
				$temp =~ s/\(//g ;
				$name = $temp ;
			}
		}
	}
	}
#Bob	usleep ($arg{sleep}) ;
	sleep ($arg{sleep}) ;
	return  %ACC ;
}

#convert to human readable numbers (as bytes)
sub conv {
  my $nr = $_[0] ;
  my @prefix = ( "","KB","MB","GB","TB","PB","EB","ZB","YB" );
  my $counter =0;
  my $ret;
  if ( $nr <= 1024 )
  {
	$ret=sprintf ("%.0fB",$nr) ;
  }
  else
  {
  	while ($nr > 1024)
  	{
		$counter++;
		$nr = $nr / 1024 ;
  	}
  	#printf "fixed nr = %.2f%s\n",$nr,$prefix[$counter]
  	$ret=sprintf ("%.2f%s",$nr,$prefix[$counter]) ;
  }
  return "$ret" ;
}

#convert to human readable numbers (as bits)
sub convb {
  my $nr = $_[0] ;
  my @prefix = ( "","Kbps","Mbps","Gbps","Tbps","Pbps","Ebps","Zbps","Ybps" );
  my $counter =0;
  my $ret;
  if ( $nr <= 1024 )
  {
	$ret=sprintf ("%.0fbps",$nr) ;
  }
  else
  {
  	while ($nr > 1024)
  	{
		$counter++;
		$nr = $nr / 1024 ;
  	}
  	#printf "fixed nr = %.2f%s\n",$nr,$prefix[$counter]
  	$ret=sprintf ("%.2f%s",$nr,$prefix[$counter]) ;
  }
  return "$ret" ;
}
