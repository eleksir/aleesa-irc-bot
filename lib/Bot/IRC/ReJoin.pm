package Bot::IRC::ReJoin;
# Re-Join to channel on /kick

use 5.018;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use English qw ( -no_match_vars );
use Encode qw (_utf8_on);

our $VERSION = '1.35'; # VERSION

# Most gears are spinning here.
sub init {
	my ($bot) = @_;

	$bot->hook (
		{
			command => 'KICK',
		},

		sub {
			my $bot = shift;
			my $msg = shift;

			# fix some utf8 flags, that are lost
			_utf8_on $msg->{forum};
			_utf8_on $msg->{full_text};
			_utf8_on $msg->{user};

			my ($who, $why) = split / \:/, $msg->{text}, 2;

			if ($who eq $bot->{nick}) {
				$bot->note ("I was kicked from $msg->{forum} by $msg->{nick} with reason $why");
				sleep 5;
				$bot->join ($msg->{forum});
				$bot->note ("Re-joining to $msg->{forum}");
			}

			return 1;
		},
	);

	return 1;
}

1;

__END__

# vim: set ft=perl noet ai ts=4 sw=4 sts=4: