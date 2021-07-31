package IRCBot;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Bot::IRC;
use BotLib::Conf qw (LoadConf);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (RunIRCBot);

my $c = LoadConf ();


sub RunIRCBot {
	my $c = LoadConf ();

	my $bot = Bot::IRC->new (
		spawn  => 2,
		daemon => {
			name        => 'aleesa-irc-bot',
			lsb_sdesc   => 'Aleesa IRC Bot',
			pid_file    => $c->{pid},
			stderr_file => $c->{log},
			stdout_file => $c->{debug_log},
		},
		connect => {
			server => $c->{server},
			port   => $c->{port},
			nick   => $c->{nick},
			name   => 'Aleesa IRC Bot',
			ssl    => $c->{ssl},
			ipv6   => 0,
		},
	);

	$bot->load ('OnMessage');  # our main plugin that handles all the incomming messages, mostly
	$bot->helps(
		about => 'I am just another chatty bot.',
	);

	# finally, run bot
	if (defined $c->{'connect_cmd'} && $c->{'connect_cmd'} ne '') {
		my @connect_cmd = map {chomp; $_} split (/\n/, $c->{'connect_cmd'});
		$bot->run (@connect_cmd);
	} else {
		$bot->run;
	}
}


1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
