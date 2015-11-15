# monitor_tc
Export from http://www.docum.org/docum.org/monitor/ 
since the author is no longer maintaining it.

Dear reader, I'm not updating these pages anymore. If you have tc or ip related questions, you can post them on the LARTC mailing list.

Console output (monitor.pl)

I use this script to test my tc setups. This scripts logs all the counters in /tmp/bb* and this can be used to graph the result.

Example output of monitor.pl :

############################# 2.325 KB/s 3.718 KB/s 9.290 KB/s  T 15.33 KB/s  G 14.73 KB/s 15.16%  24.24%  30.65% 31.69%
############################# SP1        SP2        SP3         T SP4         G SP5        PR1     PR2     PR3    PR4

Explanation :
SP1 : Bandwidth of first chain
SP2 : Bandwidth of second chain
SP3 : Bandwidth of third chain
SP4 : Total Bandwidth = SP1 + SP2 + SP3
SP5 : total SP4
PR1 : SP1 / SP4
PR2 : SP2 / SP4
PR3 : total SP1 / total SP4
PR4 : total SP2 / total SP4 

tc monitor (monitor_tc.pl)

I changed the monitor.pl script so it monitors htb classes. It creates a log file in /tmp with the value of tokens, ctokens, bytes, packets and speed of all htb classes.

Download

These scripts work for me. Sometimes I adapt them if I they are not working. You probably need to change them so they work for you.

If you add something really nice, let me know so I can update this page.

    monitor.pl : BW monitor
    monitor_html.pl : BW monitor that produces HTML
    monitor_tc.pl : HTB monitor 

