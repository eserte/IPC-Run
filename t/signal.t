#!/usr/bin/perl

=pod

=head1 NAME

signal.t - Test suite IPC::Run->signal

=cut

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
    if ( $ENV{PERL_CORE} ) {
        chdir '../lib/IPC/Run' if -d '../lib/IPC/Run';
        unshift @INC, 'lib', '../..';
        $^X = '../../../t/' . $^X;
    }
}

use Test::More;

BEGIN {
warn "win32?";
    if ($^O eq 'MSWin32') {
warn "win32!";
	plan skip_all => 'skipping';
warn "skip early!";
	exit 0;
    }
}

__END__

use IPC::Run qw( :filters :filter_imp start run );
use t::lib::Test;

#BEGIN
 {
    warn "check WIN32_MODE: " . IPC::Run::Win32_MODE();
    if ( IPC::Run::Win32_MODE() ) {
        plan skip_all => 'Skipping on Win32';
	warn "now call exit(0)";
        exit(0);
	warn "never reached!";
    }
    else {
        plan tests => 3;
    }
}

warn "never reached(2)!";

my @receiver = (
    $^X,
    '-e',
    <<'END_RECEIVER',
      my $which = "          ";
      sub s{ $which = $_[0] };
      $SIG{$_}=\&s for (qw(USR1 USR2));
      $| = 1;
      print "Ok\n";
      for (1..10) { sleep 1; print $which, "\n" }
END_RECEIVER
);

my $h;
my $out;

$h = start \@receiver, \undef, \$out;
pump $h until $out =~ /Ok/;
ok 1;
$out = "";
warn "huh? about to send USR2...";
$h->signal("USR2");
warn "signal sent...";
pump $h;
$h->signal("USR1");
pump $h;
$h->signal("USR2");
pump $h;
$h->signal("USR1");
pump $h;
ok $out, "USR2\nUSR1\nUSR2\nUSR1\n";
$h->signal("TERM");
finish $h;
ok(1);
