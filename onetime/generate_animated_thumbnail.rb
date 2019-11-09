#!/usr/bin/ruby
# サムネイル画像を生成する
# 高さ186pxに合わせる
require 'tmpdir'

outdir = './public/thumbnail'

Dir.glob("./public/illusts/*.gif") {|image|
    basename = File.basename(image).split('.').first
    ext = File.extname(image)
    outfile = "#{outdir}/#{basename}#{ext}"
    puts outfile

    Dir.mktmpdir {|tmpdir|
        mid_gif = "#{tmpdir}/mid.gif"

        system "convert -coalesce #{image} #{mid_gif}"
        system "convert #{mid_gif} -resize x186 #{outfile}"
    }
}
