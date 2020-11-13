require 'bundler/setup'

REGIONS = %w[ap-northeast-1]

BASES = {
  'amazonlinux1' => 'ruby2.5',
  'amazonlinux2' => 'ruby2.7',
}

ENV['DOCKER_BUILDKIT'] = '1'

task :default => :upload

BASES.each_key do |base|
  desc "Build layer images"
  task :build => :"build:#{base}"

  desc "Build layer image for #{base}"
  task :"build:#{base}" do
    require 'pathname'
    require 'tmpdir'

    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      iidfile = dir + 'iid'
      cidfile = dir + 'cid'

      sh(*%W[docker build --iidfile #{iidfile} --file Dockerfile --build-arg base=#{BASES[base]} docker])
      iid = iidfile.read

      sh(*%W[docker create --cidfile #{cidfile} #{iid} /bin/true])
      cid = cidfile.read

      mkdir_p 'pkg'
      sh(*%W[docker cp #{cid}:/tmp/src/pkg/layer.zip pkg/gnupg-#{base}.zip])
    ensure
      system(*%W[docker rm -f #{cid}]) if cid
    end
  end

  desc "Upload layer images"
  task :upload => :"upload:#{base}"

  desc "Upload layer image for #{base}"
  task :"upload:#{base}" => :"build:#{base}" do
    require 'base64'
    require 'aws-sdk-lambda'

    content = IO.binread("pkg/gnupg-#{base}.zip")

    layers = REGIONS.map do |region|
      client = Aws::Lambda::Client.new(region: region)

      client.publish_layer_version(
        layer_name: "gnupg-#{base}",
        description: "GnuPG binaries for #{base}",
        license_info: 'GPL-3.0-or-later',
        content: {
          zip_file: content,
        },
      )
    end

    puts layers.map(&:layer_version_arn)
  end
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
  require 'yaml'
  require 'nokogiri'
  require 'open-uri'
  require 'digest/sha2'
  require 'gpgme'
  require 'tmpdir'

  def versioncmp(a, b)
    Gem::Version.new(a) <=> Gem::Version.new(b)
  end

  def verify(version:, uri:)
    Dir.mktmpdir do |dir|
      ENV['GNUPGHOME'] = dir

      URI(uri).open('rb') do |archive|
         URI(uri + '.sig').open('rb') do |signature|
           GPGME::Ctx.new do |gpg|
             File.open('gnupg.asc') do |f|
               gpg.import_keys(GPGME::Data.from_io(f))
             end

             gpg.verify(GPGME::Data.from_io(signature), GPGME::Data.from_io(archive), nil)
             raise "No valid signatures for #{uri}" unless gpg.verify_result.signatures.any?(&:valid?)
           end
           {
             version: version,
             url: uri,
             sha256: Digest::SHA256.hexdigest(archive.tap(&:rewind).read)
           }
         end
      end
    ensure
      ENV['GNUPGHOME'] = nil
    end
  end

  latest_versions = PACKAGES.to_h do |name, opts|
    [
      name,
      Thread.new do
        re = opts[:pattern]
        index_uri = URI(opts[:uri])
        index_uri.open do |f|
          html = Nokogiri::HTML(f)
          versions = html.css('a[href]').filter_map {|e|
            href = e.attr('href')
            {version: $1, uri: index_uri.merge(href).to_s} if re =~ href
          }.sort {|a, b| -versioncmp(a[:version], b[:version]) }
          versions.first
        end
      end
    ]
  end

  latest_versions.transform_values! {|th| p verify(**th.value) }
  File.write('docker/versions.yaml', YAML.dump(latest_versions))
end
