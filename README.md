# Aleesa-IRC-bot - Simple IRC chatty bot

## About

It is based on Perl modules [Bot::IRC][1] and [Hailo][2] as
conversation generator.

Config located in **data/config.json**, sample config provided as
**data/sample_config.json**.

Bot can be run via **bin/aleesa-irc-bot** and acts as daemon.

This bot has an experimental status due to lack of thorough testing.

## Installation

In order to run this application, you need to "bootstrap" it - download and
install all dependencies and libraries.

You'll need "Development Tools" or similar group of packages, perl, perl-devel,
perl-local-lib, perl-app-cpanm, sqlite-devel, zlib-devel, openssl-devel,
libdb4-devel (Berkeley DB devel), make.

After installing required dependencies it is possible to run:

```bash
bash bootstrap.sh
```

and all libraries should be downloaded, built, tested and installed.

## Caveats

Due to hard limitations on many IRC servers, I have to implement help message
in different manner comparing to my other bots. The point is IRC does not
support multiline messages. So message must not contain newline or return
carriage symbol. So I have to split help by topics. Say thanks to author of
this bot framework help topics are so easy to implement.

[1]: https://metacpan.org/pod/Bot::IRC
[2]: https://metacpan.org/pod/Hailo
