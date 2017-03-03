# encoding: UTF-8
#
# Cookbook Name:: dovecot_test
# Recipe:: default
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2013-2015 Onddo Labs, SL.
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

include_recipe 'dovecot'

ruby_block 'ohai plugin tests' do
  block do
    unless node['dovecot']['version'].is_a?(String)
      raise 'Ohai plugin cannot get dovecot version.'
    end
    unless node['dovecot']['build-options'].is_a?(Hash) &&
           !node['dovecot']['build-options'].empty?
      raise 'Ohai plugin cannot get dovecot build options.'
    end
  end
end

include_recipe 'dovecot::create_pwfile'

# Required for integration tests:
package 'lsof'
include_recipe 'netstat'
