
package "mercurial"
package "scons"
package "gcc"
package "g++"
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
end

cookbook_file "/vagrant/ModelLibrary/gem5/Patches.tgz" do
  source "Patches.tgz"
  mode "0644"
end

remote_directory "/vagrant/ModelLibrary/gem5/amba_wrap" do
  source "amba_wrap"
end

bash "Apply Paches" do
  code <<-EOH
     cd /vagrant/ModelLibrary/gem5

    tar -zxf Patches.tgz

    for file in Patches/*;
    do
      patch < $file;
    done

      touch Patches.applied
    
  EOH
  creates "/vagrant/ModelLibrary/Patches.applied"
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


bash "compile-GEM5-with-amba" do
#  cwd Chef::Config[:file_cache_path]
#  --- I think we should build here !!!!
  code <<-EOH
     cd /vagrant/ModelLibrary/gem5
#     scons build/ARM/gem5.opt

#  now re-build the'systemc link files

#  now do a big 'link'.

  EOH
  creates "/vagrant/ModelLibrary/gem5/something else"
end
