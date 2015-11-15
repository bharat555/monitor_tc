#!/usr/bin/perl
#
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of the GNU General Public License
#       as published by the Free Software Foundation; either version
#       2 of the License, or (at your option) any later version.
#
#       Authors : Stef Coene (stef.coene@docum.orgt)
#                 http://www.docum.org

use CGI qw (:standard) ;
use Time::HiRes qw(gettimeofday);

$moni{speed} = 15 ;
$moni{sleep} = 1 ;
$moni{width} = 2000 ;
$moni{lines} = 35 ;

print header () ;
print start_html (-bgcolor=>"black",
		-head=>"<meta HTTP-EQUIV=\"REFRESH\" CONTENT=\"1\">",
		-text=>"black") ;

#print "\n<pre>\n" ;

$IPTABLES = "/usr/lib/cgi-bin/iptables";

@color = ('red',
          'yellow',
          'blue',
          'green',
          'pink') ;

$DIVIDER = $moni{speed} / $moni{width} * 1000 ;
main () ;

sub main {
  print "<font color=white>Starting monitor</font>\n" ;
  my %acc_vorige = get_chains () ;
  my @start = gettimeofday () ;
  my @old_time =gettimeofday () ;
  $lines = 0 ;

while (1) {
  if ( $lines > $moni{lines} ) { last ; }
  $lines ++ ;
  my %acc = get_chains () ;
  my @time = gettimeofday () ;
  my $diff_time = ( ($time[0]-$old_time[0]) + ($time[1]-$old_time[1])/1000000 );
  my $diff_start = ( ($time[0]-$start[0]) + ($time[1]-$start[1])/1000000 );
  @old_time = @time ;

  foreach $key (keys(%acc)) {
    my $acc = $acc{$key} - $acc_vorige{$key} ;
    $acc_vorige{$key} = $acc{$key} ;
    if ( $acc < "0" ) { next ; }
    my $acc = $acc / $diff_time ;
    $speed = speed ("$acc") ;

    $key =~ s/acc_// ;
    $acc[$key] = $acc ; 
    $speed[$key] = $speed ;
  }

  $acc_sum = sum (@acc) ;
  $tot_speed = speed ("$acc_sum") ;

  @bars = divide ( $DIVIDER, @acc) ;
  print_bars () ;

  open (FILE, ">/tmp/speed.log" ) ;
  foreach my $speed (@speed) {
    print FILE "$speed " ;
  }
  print FILE "$tot_speed\n" ;
  close FILE ;
} }

sub print_bars {
  $width = sum ( @bars ) ;
  $width = (split ('\.',$width))[0] ;
  print "<table border=0 width=$width CELLSPACING=0 CELLPADDING=0 height=1><tr>\n" ;
  my $i = "0" ;
  foreach my $bars (@bars) {
    $width = (split ('\.',$bars))[0]  ;
    if ( $acc_list{$i} ne "Y" ) { $i ++ ; next ; } 
    if ( $width > 55 ) { 
      print "<td width=$width bgcolor=$color[$i]>$speed[$i]</td>\n" ;
    } else {
      print "<td width=$width bgcolor=$color[$i]>&nbsp;</td>\n" ;
    }
    $i ++ ;
  }
  print "</tr></table>\n" ;
}

# Get the byte counter per firewall rule
sub get_chains {
  my %in ;
  @list = `$IPTABLES -n -L | grep "Chain acc_" | grep -v policy | grep -v "(0 references" | awk '{print \$2}' ` ;
  undef %acc_list ; # Nodig om alleen de lijnen te printen die een waarde hebben
  foreach my $ele (@list) {
    chomp ($ele) ;
    @list_in = `$IPTABLES -n -L -v -x | grep $ele | grep -v reference` ;
    foreach my $ele (@list_in) {
      my @ele = split (" ", $ele) ;
      $in{$ele[2]} += $ele[1] ;
    }
    $ele =~ s/acc_// ;
    $acc_list{$ele} = "Y" ;
  }
  `sleep $moni{sleep}` ;
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

sub sum {
  my $ret = "0" ;
  foreach my $ele (@_) { $ret += $ele ; }
  return $ret
}

sub divide {
  my $div = $_[0] ;
  shift (@_) ;
  my $i = 0 ;
  foreach my $ele (@_) { 
    if ( $div eq "0" ) { $ret[$i] = "0" ; }
    else { $ret[$i] = $ele / $div ; }
    $i ++ ; }
  return @ret
}
