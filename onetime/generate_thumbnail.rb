#!/usr/bin/ruby
# サムネイル画像を生成する
# 高さ186pxに合わせる

outdir = './public/thumbnail'

Dir.glob("./public/illusts/*") {|image|
    basename = File.basename(image).split('.').first
    ext = File.extname(image)
    outfile = "#{outdir}/#{basename}#{ext}"
    puts outfile

    system "convert -resize x186 #{image}[0] #{outfile}"
}
