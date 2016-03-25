#  Support whyrun
#

extend Chef::Mixin::ShellOut

def whyrun_supported?
  true
end

action :create do
  if !@current_resource.changed
    Chef::Log.info "#{@new_resource} no changes, wil not update password file"
  else
    converge_by('Updating Password file') do
      write_password_file
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::DovecotPasswordfile.new(new_resource.name)
  @current_resource.passwordFile(new_resource.passwordFile)
  @current_resource.owner(new_resource.owner)
  @current_resource.group(new_resource.group)
  @current_resource.credentials(new_resource.credentials)
  @current_resource.changed = changed?
end

private

def changed?
  local_creds = read_pwd_file
  @encrypted_credentials ||= []
  credentials_updated = false
  @current_resource.credentials.each do |user, password|
    enc_password = shell_out("/usr/bin/doveadm pw -s MD5 -p #{password}").stdout
    credentials_updated = shell_out(
      "/usr/bin/doveadm pw -t '#{local_creds[user]}' -p #{password}"
    ).exitstatus != 0 ? true : false
    @encrypted_credentials.push([user, enc_password.strip])
  end
  credentials_updated
end

def read_pwd_file
  passwordfile = ::File.open(
    @current_resource.passwordFile, ::File::CREAT | ::File::RDONLY, 0640
  )
  local_creds = {}
  passwordfile.readlines.each do |line|
    (user, crypt) = line.strip.split(':')
    local_creds[user] = crypt
  end
  local_creds
end

def write_password_file
  installer_template = Chef::Resource::Template.new(
    @current_resource.passwordFile, @run_context
  )
  installer_template.cookbook('dovecot')
  installer_template.source('password.erb')
  installer_template.sensitive(true)
  installer_template.owner(@current_resource.owner)
  installer_template.group(@current_resource.group)
  installer_template.variables(credentials:  @encrypted_credentials)
  installer_template.run_action(:create)
end
