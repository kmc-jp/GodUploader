#!/usr/bin/ruby
# サムネイル画像を生成する
# 高さ186pxに合わせる
outdir = './public/thumbnail'

Dir.glob("./public/illusts/*.gif") {|image|
    basename = File.basename(image).split('.').first
    ext = File.extname(image)
    outfile = "#{outdir}/#{basename}#{ext}"
    puts outfile

    system "convert #{image} -coalesce -resize x186 -layers optimize #{outfile}"
}
