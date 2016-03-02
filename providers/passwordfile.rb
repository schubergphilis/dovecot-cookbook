#  Support whyrun
# 

extend Chef::Mixin::ShellOut
require 'pry'


def whyrun_supported?
  true
end

action :create do
  if @current_resource.exists
    Chef::Log.info "#{ @new_resource } nothing changed, no need to update password file"
  else
    converge_by("Updating Password file") do
      writePasswordFile
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::DovecotPasswordfile.new(new_resource.name)
  @current_resource.passwordFile(new_resource.passwordFile)
  @current_resource.credentials(new_resource.credentials)
  if changed?
    @current_resource.exists = false
  else
    @current_resource.exists = true
  end
end

private

def changed?
  local_creds = readPwdFile
  @@encrypted_credentials = []
  credentials_updated = false
  current_resource.credentials.each do |user,password|
    enc_password = shell_out("/usr/bin/doveadm pw -s MD5 -p #{password}").stdout
    credentials_updated = true if shell_out(
    "/usr/bin/doveadm pw -t '#{local_creds[user]}' -p #{password}"
    ).exitstatus != 0
    @@encrypted_credentials.push([user, enc_password.strip])
  end
  credentials_updated
end

def readPwdFile
  passwordfile = ::File.open(@current_resource.passwordFile, ::File::CREAT | ::File::RDONLY, 0640)
  local_creds = {}
  passwordfile.readlines.each do |line|
    (user, crypt) = line.strip.split(':')
    local_creds[user] = crypt
  end
  local_creds
end


def writePasswordFile
  installer_template = Chef::Resource::Template.new(@current_resource.passwordFile, @run_context)
  installer_template.cookbook('dovecot')
  installer_template.source("password.erb")
  installer_template.local(false)
  installer_template.sensitive(true)
  binding.pry
  installer_template.variables({:credentials => @@encrypted_credentials})
  binding.pry
  installer_template.run_action(:create)
end

