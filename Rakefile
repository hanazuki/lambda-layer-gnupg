require 'bundler/setup'
require 'mini_portile2'
require 'pathname'

PUBKEY = (Pathname(__dir__) + 'gnupg.asc').read

task :default => :package

desc 'Build everything'
task :build => :'build:gnupg'

LDFLAGS = %[-Wl,-rpath='$$ORIGIN'/../lib]

PACKAGES = {
  gnupg: {
    name: 'GnuPG',
    depends: %i[libksba libassuan libgcrypt ntbtls npth],
    recipe: MiniPortile.new('gnupg', '2.2.18').tap {|r|
      r.files << {
        gpg:{
          key: PUBKEY,
          signature_url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2.sig",
        },
        url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2",
      }
      r.configure_options = %W[--disable-nls --disable-gpgsm --disable-gpgtar --disable-wks-tools --disable-photo-viewers --disable-card-support --disable-doc LDFLAGS=#{LDFLAGS}]
    }
  },
  libgpg_error: {
    name: 'Libgpg-error',
    depends: %i[],
    recipe: MiniPortile.new('libgpg-error', '1.36').tap {|r|
      r.files << {
        gpg:{
          key: PUBKEY,
          signature_url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2.sig",
        },
        url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2",
      }
      r.configure_options = %W[--disable-nls --enable-shared --disable-static --with-pic --disable-doc LDFLAGS=#{LDFLAGS}]
    }
  },
  libgcrypt: {
    name: 'Libgcrypt',
    depends: %i[libgpg_error],
    recipe: MiniPortile.new('libgcrypt', '1.8.5').tap {|r|
      r.files << {
        gpg:{
          key: PUBKEY,
          signature_url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2.sig",
        },
        url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2",
      }
      r.configure_options = %W[--enable-shared --disable-static --with-pic --disable-doc LDFLAGS=#{LDFLAGS}]
    }
  },
  libksba: {
    name: 'Libksba',
    depends: %i[libgpg_error],
    recipe: MiniPortile.new('libksba', '1.3.5').tap {|r|
      r.files << {
        gpg:{
          key: PUBKEY,
          signature_url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2.sig",
        },
        url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2",
      }
      r.configure_options = %W[--enable-shared --disable-static --with-pic --disable-doc LDFLAGS=#{LDFLAGS}]
    }
  },
  libassuan: {
    name: 'Libassuan',
    depends: %i[libgpg_error],
    recipe: MiniPortile.new('libassuan', '2.5.3').tap {|r|
      r.files << {
        gpg:{
          key: PUBKEY,
          signature_url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2.sig",
        },
        url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2",
      }
      r.configure_options = %W[--enable-shared --disable-static --with-pic --disable-doc LDFLAGS=#{LDFLAGS}]
    }
  },
  ntbtls: {
    name: 'ntbTLS',
    depends: %i[libgpg_error libgcrypt libksba],
    recipe: MiniPortile.new('ntbtls', '0.1.2').tap {|r|
      r.files << {
        gpg:{
          key: PUBKEY,
          signature_url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2.sig",
        },
        url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2",
      }
      r.configure_options = %W[--enable-shared --disable-static --with-pic --disable-doc LDFLAGS=#{LDFLAGS}]
    }
  },
  npth: {
    name: 'nPth',
    depends: %i[],
    recipe: MiniPortile.new('npth', '1.6').tap {|r|
      r.files << {
        gpg:{
          key: PUBKEY,
          signature_url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2.sig",
        },
        url: "https://gnupg.org/ftp/gcrypt/#{r.name}/#{r.name}-#{r.version}.tar.bz2",
      }
      r.configure_options = %W[--enable-shared --disable-static --with-pic --disable-doc LDFLAGS=#{LDFLAGS}]
    }
  },
}

PACKAGES.each do |_, package|
  recipe = package[:recipe]
  def recipe.install
    return if installed?
    execute('install', %Q(#{make_cmd} install-strip),)
  end
end

def recipe(id)
  PACKAGES[id][:recipe]
end

namespace :build do
  PACKAGES.each do |id, package|
    desc "Build #{package[:name]}"
    task id => package[:depends] do
      recipe = package[:recipe]
      recipe.cook
      recipe.activate
    end
  end
end

desc 'Create archive'
task :package => :build do
  archive = (Pathname(__dir__) + 'pkg').tap(&:mkpath) + 'layer.zip'
  rm_f archive

  ports_dir = Pathname(__dir__) + 'ports'

  exclude = %w[include/** share/aclocal/** share/common-lisp/** share/info/** lib/pkgconfig/** lib/*.la]

  PACKAGES.each do |_, package|
    recipe = package[:recipe]
    Dir.chdir(ports_dir + recipe.host + recipe.name + recipe.version) do
      sh 'zip', '-yr', archive.to_s, '.', *exclude.flat_map {|p| %W[-x #{p}] }
    end
  end
end
