package "mercurial"
package "git"
package "scons"
package "build-essential"
package "libc-dev"
package "make"
package "gcc"
package "g++"
package "python-dev"
package "swig"
package "m4"
package "lua"
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
    hg clone "http://repo.gem5.org/gem5" -r 9357
#    cd gem5
#    hg checkout stable_2012_06_28
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
     set -e
      cd /vagrant/ModelLibrary/gem5

     tar -zxf Patches.tgz

     for file in Patches/*;
     do
       patch -t -p1 < $file || (echo "Patch failed" ; exit -1)
     done
       touch Patches.applied
    
   EOH
   creates "/vagrant/ModelLibrary/gem5/Patches.applied"
 end



ruby_block "compile-GEM5-ARM" do
  block do
    IO.popen( <<-EOH
       cd /vagrant/ModelLibrary/gem5
       scons build/ARM/gem5.opt
     EOH
   ) { |f|  f.each_line { |line| puts line } }
  end
#  creates "/vagrant/ModelLibrary/gem5/build/ARM/gem5.opt"
end


ENV['http_proxy'] = Chef::Config[:http_proxy]

git "checkout gem5_ArmA15" do
  repository "http://git.greensocs.com/gem5_ArmA15.git"
  reference "master"
  destination "/vagrant/ModelLibrary/gem5_ArmA15"
  action :checkout
end

#bash "checkout gem5_ArmA15" do
#  code <<-EOH
#    cd /vagrant/ModelLibrary
#    git clone "git://git.greensocs.com/gem5_ArmA15"
#  EOH
#  creates "/vagrant/ModelLibrary/gem5_ArmA15"
#end
