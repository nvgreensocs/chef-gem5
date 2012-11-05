
package "mercurial"
package "scons"
package "gcc"
package "g++"
package "python-dev"
package "swig"
package "m4"
package "lua5.2"
package "libgoogle-perftools-dev"

bash "get-and-compile-GEM5" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    mkdir -p /vagrant/gem5
    cd /vagrant/gem5
  
    echo "Building in :"
    pwd
    hg clone "http://repo.gem5.org/gem5"
    cd gem5
    hg checkout stable_2012_06_28
    
    scons build/ARM/gem5.opt

    
  EOH
  creates "/usr/lib/gem5"
end
