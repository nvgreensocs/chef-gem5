
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

#add these packages to your versions recipy
#package "mercurial"
#package "git"
#package "scons"
#package "build-essential"
#package "libc-dev"
#package "make"
#package "gcc"
#package "g++"
#package "python-dev"
#package "swig"
#package "m4"
#package "liblua5.2-dev" 
#package "libgoogle-perftools-dev"
#package "libxerces-c-dev"


bash "Create Model Library" do
  code <<-EOH
    mkdir -p #{node[:prefix]}/ModelLibrary
  EOH
  creates "#{node[:prefix]}/ModelLibrary"
end

bash "Apply LD_LIBRARY_PATH" do
    code <<-EOH
   if [ -w /etc/ld.so.conf.d ]
   then
    echo "#{node[:prefix]}/ModelLibrary/Gem5SystemC/ArmA15/lib/" > /etc/ld.so.conf.d/gem5_armA15.conf
    fi
    mkdir -p "#{node[:prefix]}/bash.profile.d"
    echo 'export LD_LIBRARY_PATH="#{node[:prefix]}/ModelLibrary/Gem5SystemC/ArmA15/lib/:$LD_LIBRARY_PATH"' > "#{node[:prefix]}/bash.profile.d/gem5_armA15.profile"
  EOH
end

bash "Create Gem5SystemC" do
  code <<-EOH
# need to specify branch
    git clone  git://git.greensocs.com/gem5SystemC_ArmModels.git #{node[:prefix]}/ModelLibrary/Gem5SystemC
  EOH
  creates "#{node[:prefix]}/ModelLibrary/Gem5SystemC"
  environment ({ 'http_proxy' => Chef::Config[:http_proxy] })
end

bash "Update Gem5SystemC" do
  code <<-EOH
    cd #{node[:prefix]}/ModelLibrary/Gem5SystemC
    git pull origin master
  EOH
  environment ({ 'http_proxy' => Chef::Config[:http_proxy] })
end

#git "checkout gem5SystemC_ArmModels" do
#  repository "git://git.greensocs.com/gem5SystemC_ArmModels.git"
#  reference "master"
#  destination "#{node[:prefix]}/ModelLibrary/Gem5SystemC"
#  action :checkout
##  environment ({ 'http_proxy' => Chef::Config[:http_proxy] })
#end

#bash "Create Gem5SystemC" do
#  code <<-EOH
#    mkdir -p #{node[:prefix]}/ModelLibrary/Gem5SystemC
#  EOH
#  creates "#{node[:prefix]}/ModelLibrary/Gem5SystemC"
#end

bash "checkout gem5" do
  code <<-EOH
    cd #{node[:prefix]}/ModelLibrary/Gem5SystemC
    hg clone "http://repo.gem5.org/gem5" -r 9357
#    cd gem5
#    hg checkout stable_2012_06_28
  EOH
  creates "#{node[:prefix]}/ModelLibrary/Gem5SystemC/gem5"
  environment ({ 'http_proxy' => Chef::Config[:http_proxy] })
end

cookbook_file "#{node[:prefix]}/ModelLibrary/Gem5SystemC/gem5/Patches.tgz" do
  source "Patches.tgz"
  mode "0644"
end



 bash "Apply Paches" do
   code <<-EOH
     set -e
      cd #{node[:prefix]}/ModelLibrary/Gem5SystemC/gem5

     tar -zxf Patches.tgz

     for file in Patches/*;
     do
       patch -t -p1 < $file || (echo "Patch failed" ; exit -1)
     done
       touch Patches.applied
    
   EOH
   creates "#{node[:prefix]}/ModelLibrary/Gem5SystemC/gem5/Patches.applied"
 end



ruby_block "compile-GEM5-ARM" do
  block do
     IO.popen( ["bash", "-c", <<-EOH
       for i in #{node[:prexix]}/bash.profile.d/* ; do source $i ; done
       cd #{node[:prefix]}/ModelLibrary/Gem5SystemC/gem5
       scons build/ARM/gem5.opt
     EOH
   ) { |f|  f.each_line { |line| puts line } }
 end
#  creates "#{node[:prefix]}/ModelLibrary/Gem5SystemC/gem5/build/ARM/gem5.opt"
end


ENV['http_proxy'] = Chef::Config[:http_proxy]


ruby_block "compile-SYSTEMC-GEM5-ARM" do
  block do
    IO.popen( <<-EOH
       for i in #{node[:prexix]}/bash.profile.d/* ; do source $i ; done
       cd #{node[:prefix]}/ModelLibrary/Gem5SystemC/
       scons
     EOH
   ) { |f|  f.each_line { |line| puts line } }
  end
#  creates "#{node[:prefix]}/ModelLibrary/Gem5SystemC/gem5/lib"
end



