#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Encode qw/ encode decode /;
use Text::Xslate;
use Time::Piece;
use Data::Printer;

# Encode Decode subroutine
# Thanks to Mr. Motoki (http://d.hatena.ne.jp/perlcodesample/20091118/1246679588)
my $enc = 'UTF-8';
binmode STDERR, ":encoding($enc)";
sub d($) { decode($enc, shift) }
sub e($) { encode($enc, shift) }

# ソース、ターゲットファイルを読み込む
print "Type file name (source, target):\n";
my ($src, $target ) = split(/ /, <STDIN>);
chomp($target);

#言語設定
print "Type languages (source, target. e.g. JA EN):\n";
my ( $srclang, $targetlang ) = split(/ /, <STDIN>);
chomp($targetlang);

#　ハッシュの配列をもらう（Xslateで展開するため）
my @srcbody = get_body($src);
my @targetbody = get_body($target);

# 原文、訳文をXslateに渡す形にまとめる
my $segments = generate_template_arg( \@srcbody, \@targetbody );

# テンプレートエンジン起動
&generate_tmx( $segments, $srclang, $targetlang );


sub generate_tmx {
    my ( $segments, $srclang, $targetlang ) = @_;

    $srclang = $srclang // 'EN';
    $targetlang = $targetlang // 'JA';

    my $tx = Text::Xslate->new();
    my $tmx = 'translation_memory.tmx';
    open (my $out, '>', $tmx) or die $!;
    print $out $tx->render('test_template.tx', {
                            segments   => $segments,
                            srclang    => $srclang,
                            targetlang => $targetlang,
                         });
    close ($out);
}

sub generate_template_arg {
    my ( $src, $target ) = @_;

    #　配列レファレンスにハッシュレフを入れる
    my $segments;
    for my $segment (@$src) {
        my $hash_ref = {
            srcbody  => $segment,
            targetbody => shift @$target,
        };
        push (@$segments, $hash_ref);
    }

    p $segments;
    return $segments;
}

sub get_body {
    my $file = shift;
    my @body = ();

    open (my $fh, '<', e($file)) or die qq/ Can't open "$file": $!/;
    while (<$fh>) {
        chomp;
        push (@body, $_);
    }
    close ($fh);

    print "Number of $file lines: @#body\n";
    return @body;
}
