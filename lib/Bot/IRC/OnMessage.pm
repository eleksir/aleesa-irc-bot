package Bot::IRC::OnMessage;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Math::Random::Secure qw (irand);
use BotLib qw (Command RandomCommonPhrase);
use BotLib::Conf qw (LoadConf);
use BotLib::Karma qw (KarmaSet);
use BotLib::Util qw (trim utf2sha1);
use Encode qw (_utf8_on);
use Hailo;
our $VERSION = '1.35'; # VERSION

# Most gears are spinning here.
sub init {
	my ($bot) = @_;
	my $c = LoadConf ();
	my $hailo;

	$bot->hook (
		{
			command => 'PRIVMSG',
		},

		sub {
			my $bot = shift;
			my $msg = shift;
			my $text = shift;

			# fix some utf8 flags, that are lost
			_utf8_on $msg->{forum};
			_utf8_on $msg->{full_text};
			_utf8_on $msg->{user};
			my $chatid = $msg->{forum};

			# The main idea is to find out if message contains command.
			# I know that this framework contains nifty way to guess commands
			# but it detects command when bot mentiond, but'd like to send
			# commands via command sign (say, exclamation mark).
			if ($msg->{full_text} =~ qr/^\s*\Q$bot->{nick}\E[\,|\:]?\s*$/i) {
				# Someone call bot, but says only name, nothing more
				$bot->reply_to ('Чего тебе?');
			} elsif ($msg->{full_text} =~ /^\Q$bot->{nick}\E[\,|\:]?\s+(.+)/i) {
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
						$bot->note ($EVAL_ERROR);
						return;
					}
				}

				my $answer = eval {
					$hailo->{$chatid}->learn_reply ($phrase);
				};

				unless (defined $answer) {
					$bot->note ($EVAL_ERROR);
					$answer = RandomCommonPhrase ();
				}

				$bot->reply_to ($answer);
			} elsif (substr ($msg->{full_text}, -2) eq '++'  ||  substr ($msg->{full_text}, -2) eq '--') {
				# Looks like someone wants to adjust karma of the phrase
				my @arr = split /\n/, $msg->{full_text};

				if ($#arr < 1) {
					my $answer = eval {
						KarmaSet (
							$chatid,
							trim (
								substr (
									$msg->{full_text},
									0,
									-2
								)
							),
							substr ($msg->{full_text}, -2)
						);
					};

					if (defined $answer) {
						$bot->reply ($answer);
					} else {
						$bot->note ($EVAL_ERROR);
					}
				}
			} elsif (substr ($msg->{full_text}, 0, 1) eq $c->{csign}) {
				my $answer = Command ($msg->{forum}, $msg->{user}, $msg->{full_text});

				if (defined $answer && $answer ne '') {
					foreach my $str (split /\n/, $answer) {
						chomp $str;
						$str = trim ($str);

						if ($str ne '') {
							$bot->reply ($str);
							sleep 1;
						}
					}
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
						$bot->note ($EVAL_ERROR);
						return;
					}
				}

				$hailo->{$chatid}->learn ($msg->{full_text});
			}

			return 1;
		},
	);

	$bot->helps ( 
		anek       => "$c->{csign}anek - рандомный анекдот с anekdot.ru",
		анек       => "$c->{csign}анек - рандомный анекдот с anekdot.ru",
		анекдот    => "$c->{csign}анекдот - рандомный анекдот с anekdot.ru",
		buni       => "$c->{csign}buni - комикс-стрип hapi buni",
		bunny      => "$c->{csign}bunny - рандомный кролик",
		rabbit     => "$c->{csign}rabbit - рандомный кролик",
		кролик     => "$c->{csign}кролик - рандомный кролик",
		cat        => "$c->{csign}cat - рандомная кошечка",
		coin       => "$c->{csign}cat - подбросить монетку - орёл или решка?",
		монетка    => "$c->{csign}cat - подбросить монетку - орёл или решка?",
		кис        => "$c->{csign}кис - рандомная кошечка",
		dice       => "$c->{csign}dice - бросить кости",
		roll       => "$c->{csign}roll - бросить кости",
		кости      => "$c->{csign}кости - бросить кости",
		dig        => "$c->{csign}dig - заняться археологией",
		копать     => "$c->{csign}копать - заняться археологией",
		drink      => "$c->{csign}drink - какой сегодня праздник?",
		пословица  => "$c->{csign}пословица - рандомная русская пословица",
		proverb    => "$c->{csign}proverb - рандомная русская пословица",
		праздник   => "$c->{csign}праздник - какой сегодня праздник?",
		fish       => "$c->{csign}fish - порыбачить",
		fisher     => "$c->{csign}fisher - порыбачить",
		рыба       => "$c->{csign}рыба - порыбачить",
		рыбка      => "$c->{csign}рыбка - порыбачить",
		рыбалка    => "$c->{csign}рыбалка - порыбачить",
		f          => "$c->{csign}f - рандомная фраза из сборника цитат fortune_mod",
		fortune    => "$c->{csign}fortune - рандомная фраза из сборника цитат fortune_mod",
		фортунка   => "$c->{csign}фортунка - рандомная фраза из сборника цитат fortune_mod",
		fox        => "$c->{csign}fox - рандомная лисичка",
		лис        => "$c->{csign}лис - рандомная лисичка",
		friday     => "$c->{csign}friday - а не пятница ли сегодня?",
		пятница    => "$c->{csign}пятница - а не пятница ли сегодня?",
		frog       => "$c->{csign}frog - рандомная лягушка",
		лягушка    => "$c->{csign}лягушка - рандомная лягушка",
		horse      => "$c->{csign}horse - рандомная лошадка",
		лошадь     => "$c->{csign}лошадь - рандомная лошадка",
		лошадка    => "$c->{csign}лошадка - лошадка",
		karma      => "$c->{csign}karma фраза - посмотреть карму фразы",
		карма      => "$c->{csign}карма фраза - посмотреть карму фразы",
		lat        => "$c->{csign}lat - сгенерировать фразу из крылатого латинского выражения",
		лат        => "$c->{csign}лат - сгенерировать фразу из крылатого латинского выражения",
		monkeyuser => "$c->{csign}monkeyuser - комикс-стрип MonkeyUser",
		owl        => "$c->{csign}owl - рандомная сова",
		сова       => "$c->{csign}сова - рандомная сова",
		ping       => "$c->{csign}ping - попинговать бота",
		пинг       => "$c->{csign}пинг - попинговать бота",
		snail      => "$c->{csign}snail - рандомная улитка",
		улитка     => "$c->{csign}улитка - рандомная улитка",
		ver        => "$c->{csign}ver - написать что-то про версию ПО",
		version    => "$c->{csign}version - написать что-то про версию ПО",
		версия     => "$c->{csign}версия - написать что-то про версию ПО",
		w          => "$c->{csign}w Город - погода в городе",
		п          => "$c->{csign}п Город - погода в городе",
		xkcd       => "$c->{csign}xkcd - комикс-стрип с xkcb.ru",
	);

	return 1;
}

1;

__END__

# vim: set ft=perl noet ai ts=4 sw=4 sts=4: