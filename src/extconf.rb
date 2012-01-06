# Copied almost verbatim from NArray

require "mkmf"

def have_type(type, header=nil)
  printf "checking for %s... ", type
  STDOUT.flush

  src = <<"SRC"
#include <ruby.h>
SRC


  src << <<"SRC" unless header.nil?
#include <#{header}>
SRC

  r = try_link(src + <<"SRC")
  int main() { return 0; }
  int t() { #{type} a; return 0; }
SRC

  unless r
    print "no\n"
    return false
  end

  $defs.push(format("-DHAVE_%s", type.upcase))

  print "yes\n"

  return true
end

def create_conf_h(file)
  print "creating #{file}\n"
  hfile = open(file, "w")
  for line in $defs
    line =~ /^-D(.*)/
    hfile.printf "#define %s 1\n", $1
  end
  hfile.close
end

if RUBY_VERSION < '1.8'
  alias __install_rb :install_rb
  def install_rb(mfile, dest, srcdir = nil)
    __install_rb(mfile, dest, srcdir)
    archdir = dest.sub(/sitelibdir/,"sitearchdir").sub(/rubylibdir/,"archdir")
    path = ['$(srcdir)/nmatrix.h','nmatrix_config.h']
    path << ['libnmatrix.a'] if /cygwin|mingw/ =~ RUBY_PLATFORM
    for f in path
      mfile.printf "\t@$(RUBY) -r ftools -e 'File::install(ARGV[0], ARGV[1], 0644, true)' %s %s\n", f, archdir
    end
  end
else
  $INSTALLFILES = [['nmatrix.h', '$(archdir)'], ['nmatrix_config.h', '$(archdir)']]
  if /cygwin|mingw/ =~ RUBY_PLATFORM
	 $INSTALLFILES << ['libnmatrix.a', '$(archdir)']
  end
end

if /cygwin|mingw/ =~ RUBY_PLATFORM
  if RUBY_VERSION >= '1.9.0'
    $DLDFLAGS << " -Wl,--export-all,--out-implib=libnmatrix.a"
  elsif RUBY_VERSION > '1.8.0'
    $DLDFLAGS << ",--out-implib=libnmatrix.a"
  elsif RUBY_VERSION > '1.8'
    CONFIG["DLDFLAGS"] << ",--out-implib=libnmatrix.a"
    system("touch libnmatrix.a")
  else
    CONFIG["DLDFLAGS"] << " --output-lib libnmatrix.a"
  end
end

$DEBUG = true
$CFLAGS = ["-Wall -g",$CFLAGS].join(" ")

srcs = %w(
nmatrix
list
dense
)

header = "stdint.h"
unless have_header(header)
  header = "sys/types.h"
  unless have_header(header)
    header = nil
  end
end

have_type("u_int8_t", header)
have_type("uint8_t", header)
have_type("int16_t", header)
have_type("int32_t", header)
have_type("u_int32_t", header)
have_type("uint32_t", header)
have_type("int64_t", header)
have_type("u_int64_t", header)
have_type("uint64_t", header)

$objs = srcs.collect{|i| i+".o"}

create_conf_h("nmatrix_config.h")
create_makefile("nmatrix")
