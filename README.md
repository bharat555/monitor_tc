# monitor_tc
Export from http://www.docum.org/docum.org/monitor/ 
since the author is no longer maintaining it, and I think this piece of code must be preserved. 



Updated monitor_tc.pl, again

This time I recevied a mail from Bob Toxen. He update the monitor script. I renamed his version to monitor_tc_top_bis.pl. You can download it below.

    #Bob #   Tokens - The tokens of the specific class
    #Bob #   Ctokens - is the ctokens of the specific class
    #   Rate - the send bytes pr. second that the class it self gives(htb)
    #   Interval Speed - Is the bytes/sec messurement in this interval
    #   Cumulated Send - Is the amount of data that has been send while this
    #                    program has been running.
    #   Total Send - Is the total send amount sence the tc class have been
    #   started
    #
    #   The parent class is highlighted
    #
    #
    # Input parameters:
    #
    # dev=eth3        for getting tc on device eth3
    # dev="eth0 eth3" for a list of devices
    # sleep=1000000   the sleeping period between sdreen updates.
    # once=yes        display only a single iteration and without escape
    # seq.

Updated monitor_tc.pl

I received a nice email. You can download his version at the end of this page (monitor_tc_top.pl).

Hello Stef

I have rewritten your very small program monitor_tc.pl into a program like top,
but monitoring classes and data flow.

Also the program can now take several interfaces as dev input, so that you write
dev="eth0 eth3" to monitor two interfaces.

The program while running could look like this:

     14:02:32 up 51 days, 21:35,  3 users,  load average: 0.02, 0.03, 0.01
                                              Interval    Cumulated Total
    Dev  Classid   Tokens   Ctokens Rate      Speed       Send      Send
    -------------------------------------------------------------------------
    eth0 1:1       148      10353   23.99KB   13.46KB/s   40.48KB   599.54GB
    eth0 1:10      14185    13899   8.23KB    169B/s      508B      42.33GB
    eth0 1:20      14185    13899   7B        0B/s        0B        388.07GB
    eth0 1:30      5796     13160   15.54KB   13.28KB/s   39.94KB   169.01GB
    eth0 1:40      159      10363   49B       15B/s       46B       136.90MB
    eth3 2:1       -4463    173     52.00KB   56.68KB/s   170.47KB  112.82GB
    eth3 2:10      11601    16237   740B      454B/s      1.33KB    1.98GB
    eth3 2:20      -2241223 173     51.49KB   56.23KB/s   169.13KB  110.85GB



The root classes will be highlighted. Information on what the fields means is
included in the perl souce code, and attached to this mail.


I hope this program can get on you home page, because i have not got any
official homepage with opensource apps :)

I have only tested this with htb, so maby it needs some adjustments to run with
cbq, or it might even be impossible to run with cbq.

I use this program to monitor a network which i currently administrate. I wrote
the program because i could not find any programs for giving me an overview of
dataflow in the different CoS classes.

I have also made perl for mrtg, so that i can collect the very same information
over time. Maby it and this program could be useful to others.

If you have any suggestions or comments, you are welcome to mail.

Regards,
Bjarke

How to calculate bandwidth with iptables/ipchains

The firewall code in the Linux kernel has built-in byte counters. These counters register each byte that passes. So this is a very accurate number. When you read these byte counters and know the exact time, you can calculate how many bytes are processed per second. So you have the bandwidth.

Kernel 2.2.x: Each chain has a byte counter. So you have to make sure that all traffic that passes that chain belongs to exact one data stream and that all the data of that data stream passes that chain. You can read the byte counters with ipchains -L but it's much faster if you read the file /proc/net/ip_fwchains.

Kernel 2.4.x: The 2.4.x kernel has a byte counter for each firewall rule. So you don't need to create a chain for each data stream. But to make my live easy, I create that chain. You can read the byte counters with the command iptables -L -v -x.

Marking: To make sure that a data stream and a chain hold the same data, I mark the packets I put into that chain and I use that mark as a filter.

For a better explanation, read the source. It's a simple perl script.

HTML output (monitor_html.pl)

For fun, I adapted the script so it generates HTML output. I don't have an online example, but just copy it in your cgi-bin directory and surf to it with a browser.

all traffic that leaves my web-server on port 80 	all other traffic that leaves my web-server 	all traffic that enters my web-server on port 80 	all other traffic that enters my web-server


Console output (monitor.pl)

I use this script to test my tc setups. This scripts logs all the counters in /tmp/bb* and this can be used to graph the result.

Example output of monitor.pl :

    ############################# 2.325 KB/s 3.718 KB/s 9.290 KB/s  T 15.33 KB/s  G 14.73 KB/s 15.16%  24.24%  30.65%     31.69%
    ############################# SP1        SP2        SP3         T SP4         G SP5        PR1     PR2     PR3        PR4

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

