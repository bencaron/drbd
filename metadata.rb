name              "drbd"
maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs/Configures drbd."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "2.0.1"
#depends           "lvm"
depends           "yum"

%w{ rhel centos debian ubuntu }.each do |os|
  supports os
end
