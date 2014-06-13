# general
default['drbd']['version'] = "8.4"
default['drbd']['configured'] = false

# global config
default['drbd']['usage_count'] = "no"
default['drbd']['protocol'] = "C"
default['drbd']['sync_rate'] = "40M"

# pair config
default['drbd']['remote_host'] = nil
default['drbd']['internal_ip'] = nil
default['drbd']['remote_ip'] = nil
default['drbd']['port'] = 7789

# device config
default['drbd']['disk'] = nil
default['drbd']['fs_type'] = "ext3"
default['drbd']['mount'] = nil
default['drbd']['dev'] = "/dev/drbd0"
default['drbd']['master'] = false
