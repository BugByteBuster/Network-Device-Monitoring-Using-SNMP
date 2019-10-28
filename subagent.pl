#!/usr/bin/perl
use NetSNMP::agent (':all');
use NetSNMP::ASN;
use NetSNMP::OID;
my %hash;
sub hello_handler
 {
    my ($handler, $registration_info, $request_info, $requests) = @_;
    my $request;
    $unixtime = time();
    open FILE, "/tmp/A1/counters.conf" or die;
    while(<FILE>)
    {
    @carray = split (/,/,$_);
    $hash{$carray[0]} = $carray[1];
    }
    for($request = $requests; $request; $request = $request->next())
    {my $oid = $request->getOID();
        my @oidarray = split/[.]/,$oid;
        my $lastoid = $oidarray[-1];
        if ($request_info->getMode() == MODE_GET)
        {
            if ($oid == new NetSNMP::OID("1.3.6.1.4.1.4171.40.1"))
            {
                $request->setValue(ASN_COUNTER, time);
            }
                 elsif ($oid > new NetSNMP::OID("1.3.6.1.4.1.4171.40.1"))
                       {
                            $m = $lastoid-1;
                            if (exists($hash{$m}))
                            {
                                   my $ctime = $hash{$m} * $unixtime;
                                   $request->setValue(ASN_COUNTER, $ctime);
                            }
                     }
            }
     }
}
my $agent = new NetSNMP::agent();
$agent->register("script", "1.3.6.1.4.1.4171.40", \&hello_handler);

