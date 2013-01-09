
#  -------    CHEF-GEM5 --------

# LICENSETEXT
# 
#   Copyright (C) 2012 : GreenSocs Ltd
#       http://www.greensocs.com/ , email: info@greensocs.com
# 
# The contents of this file are subject to the licensing terms specified
# in the file LICENSE. Please consult this file for restrictions and
# limitations that may apply.
# 
# ENDLICENSETEXT

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
package "lua5.2"
package "libgoogle-perftools-dev"
package "libxerces-c-dev"


bash "Create Model Library" do
  code <<-EOH
    mkdir -p /vagrant/ModelLibrary
  EOH
  creates "/vagrant/ModelLibrary"
end

bash "Create Gem5SystemC" do
  code <<-EOH
    mkdir -p /vagrant/ModelLibrary/Gem5SystemC
  EOH
  creates "/vagrant/ModelLibrary/Gem5SystemC"
end

bash "checkout gem5" do
  code <<-EOH
    cd /vagrant/ModelLibrary/Gem5SystemC
    hg clone "http://repo.gem5.org/gem5" -r 9357
#    cd gem5
#    hg checkout stable_2012_06_28
  EOH
  creates "/vagrant/ModelLibrary/Gem5SystemC/gem5"
  environment ({ 'http_proxy' => Chef::Config[:http_proxy] })
end

cookbook_file "/vagrant/ModelLibrary/Gem5SystemC/gem5/Patches.tgz" do
  source "Patches.tgz"
  mode "0644"
end



 bash "Apply Paches" do
   code <<-EOH
     set -e
      cd /vagrant/ModelLibrary/Gem5SystemC/gem5

     tar -zxf Patches.tgz

     for file in Patches/*;
     do
       patch -t -p1 < $file || (echo "Patch failed" ; exit -1)
     done
       touch Patches.applied
    
   EOH
   creates "/vagrant/ModelLibrary/Gem5SystemC/gem5/Patches.applied"
 end



ruby_block "compile-GEM5-ARM" do
  block do
    IO.popen( <<-EOH
       cd /vagrant/ModelLibrary/Gem5SystemC/gem5
       scons build/ARM/gem5.opt
     EOH
   ) { |f|  f.each_line { |line| puts line } }
  end
#  creates "/vagrant/ModelLibrary/Gem5SystemC/gem5/build/ARM/gem5.opt"
end


ENV['http_proxy'] = Chef::Config[:http_proxy]

git "checkout gem5SystemC_ArmModels" do
  repository "git://git.greensocs.com/gem5SystemC_ArmModels.git"
  reference "master"
  destination "/vagrant/ModelLibrary/Gem5SystemC/gem5SystemC_ArmModels"
  action :checkout
end

ruby_block "compile-SYSTEMC-GEM5-ARM" do
  block do
    IO.popen( <<-EOH
       cd /vagrant/ModelLibrary/Gem5SystemC/
       scons
     EOH
   ) { |f|  f.each_line { |line| puts line } }
  end
#  creates "/vagrant/ModelLibrary/Gem5SystemC/gem5/lib"
end
