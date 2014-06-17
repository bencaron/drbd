
stuffpath = "test/integration"

desc "upload roles to our chef-zero server"
task :upload do
  sh "knife role from file #{stuffpath}/roles/drbd-pair-primary.json   -c #{stuffpath}/knife.rb"
  sh "knife role from file #{stuffpath}/roles/drbd-pair-secondary.json   -c #{stuffpath}/knife.rb"
end
