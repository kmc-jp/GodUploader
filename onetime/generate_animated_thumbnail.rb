#!/usr/bin/ruby
# サムネイル画像を生成する
# 高さ186pxに合わせる
require 'tmpdir'

outdir = './public/thumbnail'

Dir.glob("./public/illusts/*") {|image|
    next if `identify #{image} | wc -l`.chomp.to_i <= 1

    basename = File.basename(image).split('.').first
    ext = File.extname(image)
    outfile = "#{outdir}/#{basename}#{ext}"
    puts outfile

    Dir.mktmpdir {|tmpdir|
        frame_dir = "#{tmpdir}/frame"
        mid_gif = "#{tmpdir}/mid.gif"

        Dir.mkdir frame_dir
        delay = `identify -verbose #{image} | grep Delay`
                .lines.map {|line| line.sub(/Delay: (\d+)x100/, "\\1").to_i }
                .group_by(&:itself)
                .transform_values(&:count)
                .sort_by {|a, b| a[1] <=> b[1] }
                .last.first

        puts "delay: #{delay}"
        system "convert -coalesce #{image} #{mid_gif}"
        system "convert #{mid_gif} -resize x186 #{frame_dir}/%010d.gif"
        system "convert -loop 0 -delay #{delay} #{frame_dir}/*.gif #{outfile}"
    }
}
