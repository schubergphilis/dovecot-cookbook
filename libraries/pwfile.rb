# encoding: UTF-8
#
# Cookbook Name:: dovecot
# Library:: protocols
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

module DovecotCookbook
  # Helper module to check enabled protocols
  module Pwfile
    def self.exists?(localdata)
      return true if ::File.exist?(localdata)
    end

    def self.return_data?(input)
      data = [nil] * 7
      if input.strip.split(':').length == 2
        user, data[0] = input.strip.split(':')
      else
        user = input.strip.split(':')[0]
        data = input.strip.split(':')[1..7]
      end
      [user, data]
    end

    def self.filetohash(inputfile)
      output_entries = {}
      passwordfile = File.open(inputfile, File::RDONLY | File::CREAT, 640)
      passwordfile.readlines.each do |line|
        user, data = return_data?(line)
        output_entries[user] = data
      end
      passwordfile.close
      output_entries
    end
  end
end
