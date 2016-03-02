actions :create
default_action :create

attribute :name,            :kind_of => String, :required => true, :name_attribute => true
attribute :credentials,     :kind_of => Hash, :required => true
attribute :passwordFile,     :kind_of => String, :required => true

attr_accessor :exists

