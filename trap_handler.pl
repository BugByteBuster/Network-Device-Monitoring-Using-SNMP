#!/usr/bin/perl
use DBI;
use Net::SNMP;
use NetSNMP::TrapReceiver;

my $FQDN;
my $driver   = "SQLite";
my $database = "info.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $currentstatus;
my $currenttime;
my $dbh;
my $stmt;
my $rv;
my $count;

$dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

$stmt = qq(
    CREATE TABLE IF NOT EXISTS INFORMATION (
        DeviceName        TEXT    NOT NULL,
        CurrentStatus     INT     NOT NULL,
        ReportTime        INT     NOT NULL,
        OldStatus         INT     NOT NULL,
        OldReportTime     INT     NOT NULL
    );
);

$rv = $dbh->do($stmt);

sub my_receiver {
    foreach my $x (@{$_[1]}) {
        if ("$x->[0]" eq '.1.3.6.1.4.1.41717.10.1') {
            $FQDN = $x->[1];
            $currenttime = time();
        }
        if ("$x->[0]" eq '.1.3.6.1.4.1.41717.10.2') {
            $currentstatus = $x->[1];
        }
    }

    $FQDN =~ s/\"//gs;
    print "$FQDN\n";
    print "$currentstatus\n";

    $count = $dbh->selectrow_array("SELECT COUNT(*) FROM INFORMATION");
    
    if ($count == 0) {
        $stmt = qq(
            INSERT INTO INFORMATION(DeviceName, CurrentStatus, ReportTime, OldStatus, OldReportTime)
            VALUES ('$FQDN', '$currentstatus', '$currenttime', '$currentstatus', '$currenttime');
        );
        $rv = $dbh->do($stmt);
    } else {
        $run = 0;
        for $i (1..$count) {
            $stmt = qq(SELECT DeviceName, CurrentStatus, ReportTime, OldStatus, OldReportTime FROM INFORMATION;);
            $sth = $dbh->prepare($stmt);
            $rv = $sth->execute() or die $DBI::errstr;
            @devicename = ();
            @cstate = ();
            @ctime = ();

            while (@column = $sth->fetchrow_array()) {
                push(@devicename, $column[0]);
                push(@cstate, $column[1]);
                push(@ctime, $column[2]);
            }

            if ($FQDN eq $devicename[$i-1]) {
                $stmt = qq(
                    UPDATE INFORMATION SET CurrentStatus = '$currentstatus', ReportTime = '$currenttime',
                    OldStatus = '$cstate[$i-1]', OldReportTime = '$ctime[$i-1]' WHERE DeviceName = '$FQDN'
                );
                $rv = $dbh->do($stmt) or die $DBI::errstr;
                $run = $run + 1;
            } else {
                # Do nothing
            }
        }

        if ($run == 0) {
            $stmt = qq(
                INSERT INTO INFORMATION(DeviceName, CurrentStatus, ReportTime, OldStatus, OldReportTime)
                VALUES ('$FQDN', '$currentstatus', '$currenttime', '$currentstatus', '$currenttime');
            );
            $rv = $dbh->do($stmt);
        }
    }

    @output = ();
    @failinfo = ();
    @dangertrap = ();

    # fail
    $stmt = qq(SELECT DeviceName, ReportTime, OldStatus, OldReportTime FROM INFORMATION WHERE CurrentStatus = '3';);
    $sth = $dbh->prepare($stmt);
    $rv = $sth->execute() or die $DBI::errstr;
    $count = $dbh->selectrow_array("SELECT COUNT(*) FROM INFORMATION WHERE CurrentStatus = '3';");
    @row = ();

    for $i (1..$count) {
        push @row, $sth->fetchrow_array();
    }

    for $k (0..$count-1) {
        $k = $k + 3 * $k;
        @x = (
            "1.3.6.1.4.1.41717.20.1", OCTET_STRING, "$row[$k]",
            "1.3.6.1.4.1.41717.20.2", TIMETICKS, "$row[$k+1]",
            "1.3.6.1.4.1.41717.20.3", INTEGER, "$row[$k+2]",
            "1.3.6.1.4.1.41717.20.4", TIMETICKS, "$row[$k+3]"
        );
        push @failinfo, @x;
    }

    push @output, @failinfo;

    # danger
    $stmt = qq(
        SELECT DeviceName, ReportTime, OldStatus, OldReportTime FROM INFORMATION
        WHERE CurrentStatus = '2' AND OldStatus != '3';
    );
    $sth = $dbh->prepare($stmt);
    $rv = $sth->execute() or die $DBI::errstr;
    $count = $dbh->selectrow_array("SELECT COUNT(*) FROM INFORMATION WHERE CurrentStatus = '2' AND OldStatus != 3");
    $w = 1;
    @ro = ();

    for $i (1..$count) {
        push @ro, $sth->fetchrow_array();
    }

    $s = @ro;

    while ($w <= $s) {
        @dangertrp = (
            ".1.3.6.1.4.1.41717.30.$w", OCTET_STRING, "@ro[$w-1]",
            ".1.3.6.1.4.1.41717.30.".($w+1), TIMETICKS, "@ro[$w]",
            ".1.3.6.1.4.1.41717.30.".($w+2), INTEGER, "@ro[$w+1]",
            ".1.3.6.1.4.1.41717.30.".($w+3), TIMETICKS, "@ro[$w+2]"
        );
        push @dangertrap, @dangertrp;
        $w = $w + 4;
    }

    push @output, @dangertrap;
    print "@output\n";

    # traps
    $stmt = qq(SELECT * FROM GET;);
    $sth = $dbh->prepare($stmt);
    $rv = $sth->execute() or die $DBI::errstr;
    while (@column = $sth->fetchrow_array()) {
        push(@community, $column[0]);
        push(@ip, $column[1]);
        push(@port, $column[2]);
    }

    my ($session, $error) = Net::SNMP->session(
        -hostname  => $ip[0] || 'localhost',
        -community => $community[0] || 'public',
        -port      => $port[0] || 'port'
    );

    if (!defined $session) {
        printf "ERROR: %s.\n", $error;
        exit 1;
    } else {
        print "session created\n";
    }

    my $result = $session->trap(-varbindlist => \@output);

    if (!defined($result)) {
        print "An error occurred: " . $session->error();
    } else {
        print "successful\n";
    }
}

NetSNMP::TrapReceiver::register("all", \&my_receiver) ||
warn "failed to register our perl trap handler\n";
print STDERR "Loaded the example perl snmptrapd handler\n";
