
package "mercurial"
package "scons"

bash "get-and-compile-GEM5" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    echo "Building in :"
    pwd
    hg clone http://repo.gem5.org/gem5/rev/f75ee4849c40
    
  EOH
  creates "/usr/lib/gem5"
end
