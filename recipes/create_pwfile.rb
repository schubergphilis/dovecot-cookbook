#
# Cookbook Name:: dovecot
# Recipe:: create_pwfile
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2013-2014 Onddo Labs, SL.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
extend Chef::Mixin::ShellOut

include_recipe 'dovecot::from_package'

# The file credentials should be like:
# user:password:uid:gid:(gecos):home:(shell):extra_fields
# We ignore gecos and shell, all the others are included in the script but
# uid,gid,home,extra_Fields can be nil
# user:pass:<num>:<num>::<string>::<Extras string>

credentials = []
credentials_updated = false

if DovecotCookbook::Pwfile.exists?(node['dovecot']['conf']['password_file'])
  local_creds = DovecotCookbook::Pwfile.filetohash(
    node['dovecot']['conf']['password_file']
  )
else
  pwfile_not_present = true
end

unless pwfile_not_present puts local_creds

ruby_block 'databag_to_dovecot_userdb' do
  block do
    data_bag_item(
      node['dovecot']['databag_name'], node['dovecot']['databag_users_item']
    )['users'].each do |username, user_details|
      userdbformat = if user_details.is_a?(Array)
                       [username] + user_details
                     else
                       [username, user_details, nil, nil, nil, nil, nil, nil]
                     end
      plaintextpass = userdbformat[1]
      userdbformat[1] = shell_out("/usr/bin/doveadm pw -s MD5 -p \
                              #{plaintextpass}").stdout.tr("\n", '')

      if local_creds.key?(username) && pwfile_not_present == false
        credentials_updated = true unless DovecotCookbook::Pwfile.password_valid?(
                                            local_creds[username][0], plaintextpass
                                          )
      else
        credentials_updated = true
      end
      credentials.push(userdbformat)
    end
  end
  action :run
end

template node['dovecot']['conf']['password_file'] do
  source 'password.erb'
  owner node['dovecot']['user']
  group node['dovecot']['group']
  mode '0640'
  variables(
    credentials: credentials
  )
  only_if { credentials_updated }
end
