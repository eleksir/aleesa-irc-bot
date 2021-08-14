package IRCBot2;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use AnyEvent;
use AnyEvent::IRC;
use AnyEvent::IRC::Client;
use Date::Format::ISO8601 qw (gmtime_to_iso8601_datetime);
use Encode qw (_utf8_on _utf8_off decode encode);
use Hailo;
use BotLib qw (Command RandomCommonPhrase);
use BotLib::Conf qw (LoadConf);
use BotLib::Karma qw (KarmaSet);
use BotLib::Util qw (trim utf2sha1);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (RunIRCBot);


sub RunIRCBot {
	my $c = LoadConf ();
	my $hailo;
	my $cv = AnyEvent->condvar;
	my $irc = new AnyEvent::IRC::Client;

	$irc->reg_cb (
		irc_privmsg => sub {
			my ($self, $msg) = @_;
			my $botnick = $irc->nick ();
			my $chatid = $msg->{params}->[0];
			my $text = decode('utf8', $msg->{params}->[-1]);
			my $nick = (split /!/, $msg->{prefix})[0];
			my $answer;

			unless (defined $text) { return; }

			# The main idea is to find out if message contains command.
			# I know that this framework contains nifty way to guess commands
			# but it detects command when bot mentiond, but'd like to send
			# commands via command sign (say, exclamation mark).
			if ($text =~ qr/^\s*\Q$botnick\E[\,|\:]?\s*$/i) {
				# Someone call bot, but says only name, nothing more
				$answer = sprintf '%s, чего тебе?', $nick;
			} elsif ($text =~ /^\Q$botnick\E[\,|\:]?\s+(.+)/i) {
				# Someone wants to chit-chat with bot, lets use our brain to make an answer.
				my $phrase = trim ($1);

				unless (defined $hailo->{$chatid}) {
					my $cid = utf2sha1 ($chatid);
					$cid =~ s/\//-/xmsg;
					my $brainname = sprintf '%s/%s.sqlite', $c->{braindir}, $cid;

					$hailo->{$chatid} = eval {
						Hailo->new (
							brain => $brainname,
							order => 3
						);
					};

					unless (defined $hailo->{$chatid}) {
						warn ($EVAL_ERROR);
						return;
					}
				}

				$answer = eval {
					sprintf '%s, %s', $nick, lcfirst ($hailo->{$chatid}->learn_reply ($phrase));
				};

				unless (defined $answer) {
					warn ($EVAL_ERROR);
					$answer = sprintf '%s, %s', $nick, RandomCommonPhrase ();
				}
			} elsif (substr ($text, -2) eq '++'  ||  substr ($text, -2) eq '--') {
				# Looks like someone wants to adjust karma of the phrase
				my @arr = split /\n/, $text;

				if ($#arr < 1) {
					my $answer = eval {
						KarmaSet (
							$chatid,
							trim ( substr ($text, 0, -2) ),
							substr ($text, -2)
						);
					};

					unless (defined $answer) {
						warn ($EVAL_ERROR);
						return;
					}
				}
			} elsif (substr ($text, 0, 1) eq $c->{csign}) {
				$answer = Command ($chatid, $nick, $text);

				unless (defined $answer && $answer ne '') {
					return;
				}
			} else {
				# Default action - add phrase to brain reactor as is
				unless (defined $hailo->{$chatid}) {
					my $cid = utf2sha1 ($chatid);
					$cid =~ s/\//-/xmsg;
					my $brainname = sprintf '%s/%s.sqlite', $c->{braindir}, $cid;

					$hailo->{$chatid} = Hailo->new (
						brain => $brainname,
						order => 3
					);

					unless (defined $hailo->{$chatid}) {
						warn ($EVAL_ERROR);
						return;
					}
				}

				$hailo->{$chatid}->learn ($text);
			}

			if (defined $answer) {
					foreach my $string (split /\n/, $answer) {
						if ($string ne '') {
							_utf8_off ($string);
							$irc->send_chan ($chatid, "PRIVMSG", $chatid, $string);
						}
					}
			}

			return;
		},

		connect => sub {
			my ($pc, $err) = @_;
			if (defined $err) {
				warn "Couldn't connect to server: $err\n";
			}

			if (defined ($c->{identify}) && $c->{identify} ne '') {
				# freenode/libera.chat identification style
				$irc->send_srv (
				PRIVMSG => 'NickServ',
				sprintf ('identify %s %s', $c->{nick}, $c->{identify})
				);
			}

			for my $chan (@{$c->{channels}}) {
				$irc->send_srv ("JOIN", $chan);
			}

			return;
		},

		connfail => sub {
			warn "Connection failed, trying again";
			sleep 5;

			$irc->connect(
				$c->{server},
				$c->{port},
				{
					nick => $c->{nick},
					user => $c->{nick},
					real => $c->{nick}
				}
			);
		},

		registered => sub {
			my ($self) = @_;
			print "registered!\n";
			$irc->enable_ping (60);
			return;
		},

		disconnect => sub {
			print "disconnected: $_[1]!\n";
			sleep 5;

			$irc->connect(
				$c->{server},
				$c->{port},
				{
					nick => $c->{nick},
					user => $c->{nick},
					real => $c->{nick}
				}
			);

			return;
		},

		kick => sub {
			my ($self, $kicked_nick, $channel, $is_myself, $msg, $kicker_nick) = @_;

			if ($is_myself) {
				warn sprintf ('%s kicked me from %s with reason: %s', $kicker_nick, $channel, decode('utf8', $msg));
				sleep 3;
				$irc->send_srv ("JOIN", $channel);
			}

			return;
		},

		nick_change => sub {
			my ($self, $old_nick, $new_nick, $is_myself) = @_;

			if ($is_myself) {
				warn sprintf ('my nick have been changed from %s to %s', $old_nick, $new_nick);
			}

			return;
		},

		part => sub {
			my ($self, $nick, $channel, $is_myself, $msg) = @_;

			if ($is_myself) {
				warn sprintf ('I left %s channel', $channel);
			}

			return;
		},

		join => sub {
			my ($self, $nick, $channel, $is_myself) = @_;

			if ($is_myself) {
				warn sprintf ('I joined to %s channel', $channel);
			}

			return;
		},
	);

	# these commands will queue until the connection
	# is completly registered and has a valid nick etc.
	$irc->ctcp_auto_reply ('CLIENTINFO', ['CLIENTINFO', 'CLIENTINFO ACTION FINGER PING SOURCE TIME USERINFO VERSION']);
	$irc->ctcp_auto_reply ('ACTION',
		sub {
			my ($cl, $src, $target, $tag, $msg, $type) = @_;
			return ['ACTION', $msg];
		}
	);
	$irc->ctcp_auto_reply ('FINGER', ['FINGER', $c->{nick}]);
	$irc->ctcp_auto_reply ('PING',
		sub {
			my ($cl, $src, $target, $tag, $msg, $type) = @_;
			return ['PING', $msg];
		}
	);
	$irc->ctcp_auto_reply ('SOURCE', ['SOURCE', 'https://github.com/eleksir/aleesa-irc-bot']);
	$irc->ctcp_auto_reply ('USERINFO', ['USERINFO', $c->{nick}]);
	$irc->ctcp_auto_reply ('VERSION', ['VERSION', 'Aleesa IRC Bot/1.0']);
	$irc->ctcp_auto_reply ('TIME', ['TIME', gmtime_to_iso8601_datetime (time ()) ]);

	if ($c->{ssl}) {
		$irc->enable_ssl ();
	}

	$irc->connect (
		$c->{server},
		$c->{port},
		{
			nick => $c->{nick},
			user => $c->{nick},
			real => $c->{nick}
		}
	);

	$cv->wait;
	$irc->disconnect;
	return;
}


1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
