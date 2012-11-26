
package "mercurial"
package "git"
package "scons"
package "build-essential"
package "libc-dev"
package "make"
package "gcc-4.4"
package "g++-4.4"
package "python-dev"
package "swig"
package "m4"
package "lua5.2"
package "libgoogle-perftools-dev"
package "libxerces-c-dev"

bash "Create Model Library" do
  code <<-EOH
    mkdir -p /vagrant/ModelLibrary
  EOH
  creates "/vagrant/ModelLibrary"
end


bash "checkout gem5" do
  code <<-EOH
    cd /vagrant/ModelLibrary
    hg clone "http://repo.gem5.org/gem5"
    cd gem5
    hg checkout stable_2012_06_28
  EOH
  creates "/vagrant/ModelLibrary/gem5"
  environment ({ 'http_proxy' => Chef::Config[:http_proxy] })
end

cookbook_file "/vagrant/ModelLibrary/gem5/Patches.tgz" do
  source "Patches.tgz"
  mode "0644"
end


bash "Apply Paches" do
  code <<-EOH
     cd /vagrant/ModelLibrary/gem5

    tar -zxf Patches.tgz

    for file in Patches/*;
    do
      patch -p1 < $file;
    done

      touch Patches.applied
    
  EOH
  creates "/vagrant/ModelLibrary/gem5/Patches.applied"
end


bash "compile-GEM5-ARM" do
#  cwd Chef::Config[:file_cache_path]
#  --- I think we should build here !!!!
  code <<-EOH
     cd /vagrant/ModelLibrary/gem5
     scons build/ARM/gem5.opt
  EOH
  creates "/vagrant/ModelLibrary/gem5/build/ARM/gem5.opt"
end

bash "checkout gem5_ArmA15" do
  code <<-EOH
    cd /vagrant/ModelLibrary
    git clone "git://git.greensocs.com/gem5_ArmA15"
  EOH
  creates "/vagrant/ModelLibrary/gem5_ArmA15"
end
