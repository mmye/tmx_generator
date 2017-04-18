#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Encode qw( encode decode );
use Text::Xslate;
use Time::Piece;
use Data::Printer;
use Data::Section::Simple qw( get_data_section );

# Encode Decode subroutine
# Thanks to Mr. Motoki (http://d.hatena.ne.jp/perlcodesample/20091118/1246679588)
my $enc = 'UTF-8';
binmode STDERR, ":encoding($enc)";
sub d($) { decode($enc, shift) }
sub e($) { encode($enc, shift) }

# ソース、ターゲットファイルを読み込む
print "Enter source file names (in order of source and target):\n";
my ($src, $target ) = split(/ /, <STDIN>);
chomp($target);

#言語設定
print "Enter languages for source and target. (e.g. JA EN):\n";
my ( $srclang, $targetlang ) = split(/ /, <STDIN>);
chomp($targetlang);

#TMファイルの名前入力
print "Enter TM file name (e.g. hoge.tmx):\n";
my $tmx_filename = <STDIN>;
chomp($tmx_filename);
warn $tmx_filename,"\n";

#　ハッシュの配列をもらう（Xslateで展開するため）
my @srcbody = get_body($src);
my @targetbody = get_body($target);

# 原文、訳文をXslateに渡す形にまとめる
my $segments = prepare_arg( \@srcbody, \@targetbody );

# テンプレートエンジン起動
&generate_tmx( $segments, $srclang, $targetlang );

sub get_body {
    my $file = shift;
    my @body = ();

    open (my $fh, '<', $file) or die qq/ Can't open "$file": $!/;
    while (<$fh>) {
        chomp;
        # Windowsの改行がChompで削除できない場合あり
        # ソース：http://bio-info.biz/tips/perl_chomp.html
        $fh =~s/\x0D\x0A$|\x0D$|\x0A$//;

        # 空文節はスキップ
        if($fh) {
        	push (@body, $_);
    	}
    }
    close ($fh);

    return @body;
}

sub prepare_arg {
    my ( $src, $target ) = @_;

    #　配列レファレンスにハッシュレフを入れる
    my $segments;
    for my $segment (@$src) {
        my $hash_ref = +{
            srcbody  => $segment,
            targetbody => shift @$target,
        };
        push (@$segments, $hash_ref);
    }

sub generate_tmx {
    my ( $segments, $srclang, $targetlang ) = @_;

    $srclang = $srclang // 'EN';
    $targetlang = $targetlang // 'JA';

    # get_data_section()でDATAのパスが読めない
    #my $vpath = Data::Section::Simple->new()->get_data_section();
    my $tx = Text::Xslate->new(
        #path => [$vpath],
    	);

    my $tmx = $tmx_filename;
    open (my $out, '>', $tmx) or die $!;
    print $out $tx->render('tm_template.tx', +{
                            segments   => $segments,
                            srclang    => $srclang,
                            targetlang => $targetlang,
                         });
    close ($out);
}


    p $segments;
    return $segments;
}

#__DATA__
#
#@@tm_template.tx
#<?xml version="1.0" encoding="UTF-8"?>
#<!DOCTYPE tmx SYSTEM "tmx14.dtd">
#<tmx version="1.4">
#  <header creationtool="OmegaT" o-tmf="OmegaT TMX" adminlang="<: $srclang :>" datatype="plaintext" creationtoolversion="4.0.1_0_9319:9320" segtype="sentence" srclang="<: $targetlang :>"/>
#  <body>
#  : for $segments -> $segment {
#    <tu>
#      <tuv xml:lang="<: $srclang :>">
#        <seg><: $segment.srcbody :></seg>
#      </tuv>
#      <tuv xml:lang="<: $targetlang :>" creationid="Text::Xslate" creationdate="<: $created_at :>">
#        <seg><: $segment.targetbody :></seg>
#      </tuv>
#    </tu>
#  :}
#  </body>
#</tmx>
#