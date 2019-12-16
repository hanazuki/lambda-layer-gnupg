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
