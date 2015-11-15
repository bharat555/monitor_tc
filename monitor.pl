#!/usr/bin/perl

#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of the GNU General Public License
#       as published by the Free Software Foundation; either version
#       2 of the License, or (at your option) any later version.
#
#       Authors : Stef Coene (stef.coene@docum.orgt)
#                 http://www.docum.org

# Procents are rounded, but speed not (yet)

# Q: Wat will be monitored ?
# A: Each firewall rule that will match a chain with the name acc_*.
#    * = number ! ! ! ! ! ! ! AND started from 0
#    For each *, an entry will created.

# CHANGELOG
# version 0.5 (28/06/02)
#   I swicthed over to the Time:HiRes perl module
# version 0.4 (05/06/01)
#   Logging last line to proces in other scripts to /tmp/monitor.log
#     Used in testing bounded parameter
# version 0.3 (22/05/01)
#   Added kernel 2.4.x support
# version 0.2 (22/04/01)
#   added logging of numbers for so you can plot images with xplot
# version 0.1 (19/04/01)
#   First numbered release :-)
#   uploaded to belgacom.net

# These options can be changed on the command line:
#    for instance "./monitor.pl bars_len=20" (no spaces allowed)

#$arg{numbers} = "no" ;		# =no : no numbers
use Time::HiRes qw(gettimeofday);

$arg{bars_len} = "30" ;		# length of bars, = 0 : no bars
$arg{short_prct} = "yes" ;	# =yes : last precent not printed
$arg{max_class} = "4" ; 	# maximum number of classes processed
$arg{logs} = "yes" ;		# =yes : logfiles written to /tmp/bb*
$sleep = "1" ;				# seconds between readings
$arg{batch} = "yes" ;		# =yes : logging last line to /tmp/monitor.log

foreach my $arg (@ARGV) {
  @split = split ( "=", $arg) ;
  if ( $split[1] eq "" ) {
     print "Error : argument $arg ignored\n  Enter to continue ... " ;
     <STDIN>;
  }
  $arg{$split[0]} = $split[1] ;
}

# Guessing location of iptables
if (-x "/sbin/iptables") {
  $IPTABLES="/sbin/iptables";
} elsif (-x "/usr/sbin/iptables") {
  $IPTABLES="/usr/sbin/iptables";
} elsif (-x "/usr/local/sbin/iptables") {
  $IPTABLES="/usr/local/sbin/iptables";
} else {
  $IPTABLES="";
}

$arg{max_class} -- ;
if ( $arg{logs} eq "yes" ) {
  system ("rm /tmp/bb*log") ;
}

if ( $arg{batch} eq "yes" ) {
  system ("rm /tmp/monitor.log 2> /dev/null") ;
}

kernel () ; # 2.2.x or 2.4.x
set_colors () ;
main () ;

sub main {
  print "$clear" ;
  my %acc_vorige = get_chains () ;
  @start = gettimeofday () ;
  @old_time = gettimeofday () ;

while (1) {
  my %acc = get_chains () ;
  my $diff_time = ( ($time[0]-$old_time[0]) + ($time[1]-$old_time[1])/1000000 );
  my $diff_start = ( ($time[0]-$start[0]) + ($time[1]-$start[1])/1000000 );
  @old_time = @time ;

  foreach $key (keys(%acc)) {
    my $acc = $acc{$key} - $acc_vorige{$key} ;
    $acc_vorige{$key} = $acc{$key} ;
    if ( $acc < "0" ) { next ; }
    my $speed = $acc / $diff_time ;
    $speed = speed ("$speed") ;

    $key =~ s/acc_// ;
    if ( $key > $arg{max_class} ) { next ; } 
    $acc[$key] = $acc ; 
    $acc_tot[$key] = $acc_tot[$key] + $acc ;
    $speed[$key] = $speed ;
  }

  $acc_sum = sum (@acc) ;
  $acc_tot_sum = sum (@acc_tot) ;

  # Bars
  if ( $arg{bars_len} != "0" ) {
    @bars = div (($acc_sum/$arg{bars_len}), @acc) ;
    my $bars_rest = $arg{bars_len} - sum (@bars) ;

    print_bars (@bars) ;

    print "$reset" ;
    print "-" x $bars_rest ;
    print " " ;
  }

  if ( $arg{numbers} ne "no" ) {
    print_speed (@speed) ;

  # total speed
    my $tot_speed = $acc_sum / $diff_time ;
    $tot_speed = speed ("$tot_speed") ;
    if ( $arg{logs} eq "yes" ) {
      open (FILE, ">>/tmp/bb_speed.log" ) ;
        print FILE "$tot_speed\n" ;
      close FILE ;
    }
    print " T $tot_speed$reset " ;

  # total global speed
    my $tot_speed = $acc_tot_sum / $diff_start ;
    $tot_speed = speed ("$tot_speed") ;
    if ( $arg{logs} eq "yes" ) {
      open (FILE, ">>/tmp/bb_speed_ave.log" ) ;
        print FILE "$tot_speed\n" ;
      close FILE ;
    }
    print " G $tot_speed$reset " ;

  # percent
    @acc_print = div ($acc_sum, @acc) ;
    $type = "" ;
    prct (@acc_print) ;

  # global percent
    @acc_tot_print = div ($acc_tot_sum, @acc_tot) ;
    $type = "ave" ;
    prct (@acc_tot_print) ;

    if ( $arg{batch} eq "yes" ) { 
      open (BATCH, ">/tmp/monitor.log" ) ;
      print BATCH "$tot_speed @acc_tot_print\n" ;
      close (BATCH) ;
    }
  }
  print "$reset\n" ;
} }

sub prct {
  my $ret = "" ;
  my @a = @_ ; 
  my $i = "0" ;

  if ( $arg{short_prct} eq "yes" ) { $#a-- ; }

  foreach my $ele (@a) {
    $ele = $ele + 0.00005 ;
    my @split1 = split ('\.', $ele) ;
    @split1 = split ("", $split1[1]) ;
    my $ret1 = $split1[0] ;
    if ( $split1[1] eq "" ) { $ret1 .= "0" ; }
    else { $ret1 .= $split1[1] ; }
 
    $ret1 .= "." ;
 
    if ( $split1[2] eq "" ) { $ret1 .= "0" ; }
    else { $ret1 .= $split1[2] ; }
 
    if ( $split1[3] eq "" ) { $ret1 .= "0" ; }
    else { $ret1 .= $split1[3] ; }
    if ( $arg{logs} eq "yes" ) {
      open (FILE, ">>/tmp/bb_prct_$type\_$i.log" ) ;
        print FILE "$ret1\n" ;
      close FILE ;
    }
    $ret .= $color[$i] . $ret1 . "%" . $reset . " " ;
    $i ++ ;
  }
  print "$ret " ;
}

sub print_bars {
  my @bars = @_ ;
  my $i = "0" ;
  foreach my $bars (@bars) {
    print "$color[$i]*" ;
    print "." x $bars ;
    $i ++ ;
  }
}

sub print_speed {
  my @speed = @_ ;
  my $i = "0" ;
  foreach my $speed (@speed) {
    if ( $arg{logs} eq "yes" ) {
      open (FILE, ">>/tmp/bb_speed_$i.log" ) ;
        print FILE "$speed\n" ;
      close FILE ;
    }
    print "$color[$i]$speed$reset " ;
    $i ++ ;
  }
}

# Get the byte counter per firewall rule
sub get_chains {
  my %in ;
  if ( $kernel eq "2.2") { 
    @list_in = `cat /proc/net/ip_fwchains  | grep acc_` ;
    foreach my $ele (@list_in) {
      my @ele = split (" ", $ele) ;
      $in{$ele[17]} += $ele[9] ;
    }
  } else {
    @list_in = `$IPTABLES -L -n -v -x | grep acc_ | grep -v reference` ;
    foreach my $ele (@list_in) {
      my @ele = split (" ", $ele) ;
      $in{$ele[2]} += $ele[1] ;
    }
  }
  `sleep $sleep` ;
  return  %in ;
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

sub set_colors {
  $reset    = "\033[00m"  ;
  $zwart    = "\033[40m\033[37m" ;
  $rood     = "\033[41m\033[37m" ;
  $groen    = "\033[42m\033[37m" ;
  $bruin    = "\033[43m\033[37m" ;
  $blauw    = "\033[44m\033[37m" ;
  $paars    = "\033[45m\033[37m" ;
  $cyan     = "\033[46m\033[37m" ;
  $wit      = "\033[47m\033[31m" ;
  $clear    = `clear` ;

#print "$zwart zwart ##++**\n" ;
#print "$rood rood ##++**\n" ;
#print "$groen groen ##++**\n" ;
#print "$bruin bruin ##++**\n" ;
#print "$blauw blauw ##++**\n" ;
#print "$magneta magneta ##++**\n" ;
#print "$paars paars  ##++**\n" ;
#print "$cyan cyan  ##++**\n" ;
#print "$wit wit ##++**\n" ;
#print "$reset reset ##++**\n" ;

  $color[0] = $rood ;
  $color[1] = $groen ;
  $color[2] = $blauw ;
  $color[3] = $paars ;
  $color[4] = $cyan ;
  $color[5] = $geel ;
}

sub sum {
  my $ret = "0" ;
  foreach my $ele (@_) { $ret += $ele ; }
  return $ret
}

sub div {
  my $div = $_[0] ;
  shift (@_) ;
  my $i = 0 ;
  foreach my $ele (@_) { 
    if ( $div eq "0" ) { $ret[$i] = "0" ; }
    else { $ret[$i] = $ele / $div ; }
    $i ++ ; }
  return @ret
}

sub kernel {
  #open(PROC, "/proc/version");
  #my $proc = <PROC> ;
  #close (PROC) ;

  my @split = split(/\s/,$_);
  (my $k1, my $k2, my $k3) = split(/\./,$split[2]);
  if ($k2 == 2) {
    if ($IPCHAINS ne "") {
      $kernel="2.2";
      if (! -e "/proc/net/ip_fwchains") { 
         print "Found kernel 2.2.x, but no ipchains support\n\t/proc/net/ip_fwchains not found\n";
      }
    }
  } elsif ($k2 == 4) {
    if ($IPTABLES ne "") {
      $kernel="2.4";
    } else {
      print "Found kernel 2.4.x, but iptables not found\n";
      exit 1;
    }
  } else {
    print "Sytem not supported: $split[2]\n";
  }
}

