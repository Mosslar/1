#!/usr/bin/perl -W
use strict;
use Switch;
use Net::Telnet::Cisco;

my $IP    = @ARGV[0];
my $login = @ARGV[1];
my $pass  = @ARGV[2];
my $qq;
my $godz = 3600;
my @offline;
my @niezrestartowany;
my @zrestartowany;
my @niezarejstrowany;

sub up2sec {
    $_ = $1;
    my $sec;
    switch ($1) {
        case (/^\d+d\d+h\d+m$/) {
            $_ =~ /^(\d+)d(\d+)h(\d+)m$/;
            $sec = ( $1 * 24 * 60 + $2 * 60 + $3 ) * 60;
        }
        case (/^\d+d\d+h$/) {
            $_ =~ /^(\d+)d(\d+)h$/;
            $sec = ( $1 * 24 * 60 + $2 * 60 ) * 60;
        }
        case (/^\d+d$/) {
	    $_ =~ /^(\d+)d$/;
	    $sec = ( $1 * 24 * 60 ) * 60; }
        case (/^\d+h\d+m$/) {
            $_ =~ /^(\d+)h(\d+)m$/;
            $sec = ( $1 * 60 + $2 ) * 60;
        }
        case (/^\d+h$/)     {
	    $_ =~ /^(\d+)h$/;
	    $sec = ( $1 * 60 ) * 60;
	}
        case (/^\d+\:\d+$/) {
	    $_ =~ /^(\d+)\:(\d+)$/;
	    $sec = ( $1 * 60 ) + $2;
	}
    }
    return $sec;
}


open( FH, "CM_lista.txt" );
my @plik = <FH>;
close FH;

open( my $FH, ">", "CM_wynik.txt" );
$FH->autoflush(1);

my $session = Net::Telnet::Cisco->new( Host => "$IP" );
$session->login( "$login", "$pass" );

foreach (@plik) {
    my @m = split('');
    my $mac = "$m[0]$m[1]$m[2]$m[3].$m[4]$m[5]$m[6]$m[7].$m[8]$m[9]$m[10]$m[11]";
    my $com = "sho cable modem $mac ver | i Total Time";
    my $czas;
    $qq++;
    my @output = $session->cmd("$com");
    $_ = "$mac @output";
    chomp();

    if (/Total Time Online/) {
        s/\s+/\ /g;
        $_ =~ /$mac\ Total\ Time\ Online\ \:\ (.+?)\ (.+?)\ /g;

        switch ($1) {
#            $qq++;
            $czas = up2sec();
            case { $czas == 0 }
            {
                print $FH "$qq\t$mac\toffline\t\t$1\t$czas" . "s\n";
                push @offline, $mac;
            }
            case { $czas < $godz }
            {
                print $FH "$qq\t$mac\tzrestartowany\t$1\t$czas" . "s\n";
                push @zrestartowany, $mac;
            }
            case { $czas > $godz }
            {
                print $FH "$qq\t$mac\tbez restartu\t$1\t$czas" . "s\n";
                push @niezrestartowany, $mac;
            }
        }

    }
    else {
#        $qq++;
        print $FH "$qq\t$mac\tunregistered\tBRAK\tBRAK\n";
        push @niezarejstrowany, $mac;

    }

}

print "
Wszystkich:\t\t".@plik."

Offline:\t\t".@offline."
Niezarejstrowacych:\t".@niezarejstrowany."

Zrestartowanych:\t".@zrestartowany."
Niezrestartowanych:\t".@niezrestartowany."

";

my $suma=@offline+@niezarejstrowany+@zrestartowany+@niezrestartowany;
print "Suma wszystkich: $suma\n";

close FH;
