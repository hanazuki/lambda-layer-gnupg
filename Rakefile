require 'bundler/setup'

REGIONS = %w[ap-northeast-1]

task :default => :upload
task :build do
  require 'pathname'
  require 'tmpdir'

  Dir.mktmpdir do |dir|
    dir = Pathname(dir)
    iidfile = dir + 'iid'
    cidfile = dir + 'cid'

    sh(*%W[docker build --iidfile #{iidfile} -f Dockerfile docker])
    iid = iidfile.read

    sh(*%W[docker create --cidfile #{cidfile} #{iid} /bin/true])
    cid = cidfile.read

    mkdir_p 'pkg'
    sh(*%W[docker cp #{cid}:/tmp/src/pkg/layer.zip pkg/])
  ensure
    system(*%W[docker rm -f #{cid}]) if cid
  end
end

task :upload => :build do
  require 'base64'
  require 'aws-sdk-lambda'

  content = IO.binread('pkg/layer.zip')

  layers = REGIONS.map do |region|
    client = Aws::Lambda::Client.new(region: region)

    client.publish_layer_version(
      layer_name: 'gnupg',
      description: 'GnuPG binaries',
      license_info: 'GPL-3.0-or-later',
      content: {
        zip_file: content,
      },
    )
  end

  puts layers.map(&:layer_version_arn)
end

PACKAGES = {
  'gnupg' => {
    uri: 'https://gnupg.org/ftp/gcrypt/gnupg/',
    pattern: /\Agnupg-([\d.]+)\.tar\.bz2\z/,
  },
  'libgpg-error' => {
    uri: 'https://gnupg.org/ftp/gcrypt/libgpg-error/',
    pattern: /\Alibgpg-error-([\d.]+)\.tar\.bz2\z/,
  },
  'libgcrypt' => {
    uri: 'https://gnupg.org/ftp/gcrypt/libgcrypt/',
    pattern: /\Alibgcrypt-([\d.]+)\.tar\.bz2\z/,
  },
  'libksba' => {
    uri: 'https://gnupg.org/ftp/gcrypt/libksba/',
    pattern: /\Alibksba-([\d.]+)\.tar\.bz2\z/,
  },
  'libassuan' => {
    uri: 'https://gnupg.org/ftp/gcrypt/libassuan/',
    pattern: /\Alibassuan-([\d.]+)\.tar\.bz2\z/,
  },
  'ntbtls' => {
    uri: 'https://gnupg.org/ftp/gcrypt/ntbtls/',
    pattern: /\Antbtls-([\d.]+)\.tar\.bz2\z/,
  },
  'npth' => {
    uri: 'https://gnupg.org/ftp/gcrypt/npth/',
    pattern: /\Anpth-([\d.]+)\.tar\.bz2\z/,
  },
}

task :watch do
  require 'json'
  require 'nokogiri'
  require 'open-uri'

  def versioncmp(a, b)
    Gem::Version.new(a) <=> Gem::Version.new(b)
  end

  latest_versions = PACKAGES.to_h do |name, opts|
    re = opts[:pattern]
    uri = URI(opts[:uri])
    uri.open do |f|
      html = Nokogiri::HTML(f)
      links = html.css('a[href]').filter_map {|e| [$1, e] if re =~ e.attr('href') }
      links.sort! {|a, b| -versioncmp(a[0], b[0]) }
      p [name, links.map{|l| l[0] }]
      [name, links[0][0]]
    end
  end

  File.write('docker/versions.json', JSON.dump(latest_versions))
end
