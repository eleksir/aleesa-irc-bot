package BotLib;

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Carp qw (carp);
use Math::Random::Secure qw (irand);
use BotLib::Anek qw (Anek);
use BotLib::Archeologist qw (Dig);
use BotLib::Buni qw (Buni);
use BotLib::Conf qw (LoadConf);
use BotLib::Drink qw (Drink);
use BotLib::Fisher qw (Fish);
use BotLib::Fortune qw (Fortune);
use BotLib::Fox qw (Fox);
use BotLib::Friday qw (Friday);
use BotLib::Image qw (Rabbit Owl Frog Horse Snail);
use BotLib::Karma qw (KarmaGet);
use BotLib::Kitty qw (Kitty);
use BotLib::Lat qw (Lat);
use BotLib::Monkeyuser qw (Monkeyuser);
use BotLib::Proverb qw (Proverb);
use BotLib::Util qw (trim utf2sha1);
use BotLib::Weather qw (Weather);
use BotLib::Xkcd qw (Xkcd);

use version; our $VERSION = qw (1.0);
use Exporter qw (import);
our @EXPORT_OK = qw (Command RandomCommonPhrase);

my $c = LoadConf ();

sub RandomCommonPhrase () {
	my @myphrase = (
		'Так, блядь...',
		'*Закатывает рукава* И ради этого ты меня позвал?',
		'Ну чего ты начинаешь, нормально же общались',
		'Повтори свой вопрос, не поняла',
		'Выйди и зайди нормально',
		'Я подумаю',
		'Даже не знаю что на это ответить',
		'Ты упал такие вопросы девочке задавать?',
		'Можно и так, но не уверена',
		'А как ты думаешь?',
	);

	return $myphrase[irand ($#myphrase + 1)];
}

sub Command {
	my $chatid = shift;
	my $chattername = shift;
	my $text = shift;

	my $reply;

	if (substr ($text, 1, 2) eq 'w '  ||  substr ($text, 1, 2) eq 'п ') {
		my $city = substr $text, 2;
		$reply = Weather ($city) =~ tr/\n/ /r;
	} elsif (substr ($text, 1) eq 'anek'  ||  substr ($text, 1) eq 'анек' || substr ($text, 1) eq 'анекдот' ) {
		$reply = Anek ();
	} elsif (substr ($text, 1) eq 'coin' || substr ($text, 1) eq 'монетка') {
		if (rand (101) < 0.016) {
			$reply = "ребро";
		} else {
			if (irand (2) == 0) {
				if (irand (2) == 0) {
					$reply = 'орёл';
				} else {
					$reply = 'аверс';
				}
			} else {
				if (irand (2) == 0) {
					$reply = 'решка';
				} else {
					$reply = 'реверс';
				}
			}
		}
	} elsif (substr ($text, 1) eq 'roll' || substr ($text, 1) eq 'dice' || substr ($text, 1) eq 'кости') {
		$reply = sprintf "На первой кости выпало %d, а на второй — %d.", irand (6) + 1, irand (6) + 1;
	} elsif (substr ($text, 1) eq 'version'  ||  substr ($text, 1) eq 'ver') {
		$reply = 'Версия нуль.чего-то_там.чего-то_там';
	} elsif (substr ($text, 1) eq 'help'  ||  substr ($text, 1) eq 'помощь') {
		$reply = "Попробуй '$c->{nick}, help' без кавычек, должно помочь.";
	} elsif (substr ($text, 1) eq 'lat'  ||  substr ($text, 1) eq 'лат') {
		$reply = Lat ();
	} elsif (substr ($text, 1) eq 'cat'  ||  substr ($text, 1) eq 'кис') {
		$reply = Kitty ();
	} elsif (substr ($text, 1) eq 'fox'  ||  substr ($text, 1) eq 'лис') {
		$reply = Fox ();
	} elsif (substr ($text, 1) eq 'frog'  ||  substr ($text, 1) eq 'лягушка') {
		$reply = Frog ();
	} elsif (substr ($text, 1) eq 'horse'  ||  substr ($text, 1) eq 'лошадь'  || substr ($text, 1) eq 'лошадка') {
		$reply = Horse ();
	} elsif (substr ($text, 1) eq 'snail'  ||  substr ($text, 1) eq 'улитка') {
		$reply = Snail ();
	} elsif (substr ($text, 1) eq 'dig'  ||  substr ($text, 1) eq 'копать') {
		$reply = Dig ($chattername);
	} elsif (substr ($text, 1) eq 'fish'  ||  substr ($text, 1) eq 'fisher'  ||  substr ($text, 1) eq 'рыба'  ||  substr ($text, 1) eq 'рыбка'  ||  substr ($text, 1) eq 'рыбалка') {
		$reply = Fish ($chattername);
	} elsif (substr ($text, 1) eq 'buni') {
		$reply = Buni ();
	} elsif (substr ($text, 1) eq 'xkcd') {
		$reply = Xkcd ();
	} elsif (substr ($text, 1) eq 'monkeyuser') {
		$reply = Monkeyuser ();
	} elsif (substr ($text, 1) eq 'drink' || substr ($text, 1) eq 'праздник') {
		$reply = Drink ();
	} elsif (substr ($text, 1) eq 'bunny' || substr ($text, 1) eq 'rabbit' || substr ($text, 1) eq 'кролик') {
		$reply = Rabbit ();
	} elsif (substr ($text, 1) eq 'owl' || substr ($text, 1) eq 'сова') {
		$reply = Owl ();
	} elsif ((length ($text) >= 6 && (substr ($text, 1, 6) eq 'karma ' || substr ($text, 1, 6) eq 'карма '))  ||  substr ($text, 1) eq 'karma'  ||  substr ($text, 1) eq 'карма') {
		my $mytext = '';

		if (length ($text) > 6) {
			$mytext = substr $text, 7;
			chomp $mytext;
			$mytext = trim $mytext;
		} else {
			$mytext = '';
		}

		$reply = KarmaGet ($chatid, $mytext);
	} elsif (substr ($text, 1) eq 'friday'  ||  substr ($text, 1) eq 'пятница') {
		$reply = Friday ();
	} elsif (substr ($text, 1) eq 'proverb'  ||  substr ($text, 1) eq 'пословица') {
		$reply = Proverb ();
	} elsif (substr ($text, 1) eq 'fortune'  ||  substr ($text, 1) eq 'фортунка'  ||  substr ($text, 1) eq 'f'  ||  substr ($text, 1) eq 'ф') {
		my $phrase = Fortune ();
		$reply = $phrase;
	} elsif (substr ($text, 1) eq 'ping') {
		$reply = 'Pong.';
	} elsif (substr ($text, 1) eq 'пинг') {
		$reply = 'Понг.';
	} elsif (substr ($text, 1) eq 'kde' || substr ($text, 1) eq 'кде') {
		my @phrases = (
			'Нет, я не буду поднимать вам плазму.',
			'Повторяйте эту мантру по утрам не менее 5 раз: "Плазма не падает." И, возможно, она перестанет у вас падать.'
		);

		$reply = $phrases[irand ($#phrases + 1)];
	} elsif (substr ($text, 1) eq '=(' || substr ($text, 1) eq ':(' || substr ($text, 1) eq '):') {
		$reply = ':)';
	} elsif (substr ($text, 1) eq '=)' || substr ($text, 1) eq ':)' || substr ($text, 1) eq '(:') {
		$reply = ':D';
	}

	return $reply;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
