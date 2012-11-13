
package "mercurial"
package "scons"
package "gcc"
package "g++"
package "python-dev"
package "swig"
package "m4"
package "lua5.2"
package "libgoogle-perftools-dev"

depends "chef-amba-kit"

cookbook_file "/tmp/Patches.tgz" do
  source "Patches.tgz"
  mode "0644"
end


bash "get-and-compile-GEM5" do
  cwd Chef::Config[:file_cache_path]
#  --- I think we should build here !!!!
  code <<-EOH
    mkdir -p /vagrant/gem5
    cd /vagrant/gem5
  
    echo "Building in :"
    pwd
    hg clone "http://repo.gem5.org/gem5"
    cd gem5
    hg checkout stable_2012_06_28

    cp /tmp/Patches.tgz .
    tar -zxf Patches.tgz

    for file in Patches/*
    do
      patch << ${file}
    done
    
    scons build/ARM/gem5.opt

#  now re-build the'systemc link files

#  now do a big 'link'.

  EOH
  creates "/usr/lib/gem5"
end
