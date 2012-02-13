#
# Cookbook Name:: postgresql
# Recipe:: server
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)#
# Copyright 2009-2011, Opscode, Inc.
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

include_recipe "postgresql::client"

case node[:postgresql][:version]
when "8.3"
  node.default[:postgresql][:ssl] = "off"
else # > 8.3
  node.default[:postgresql][:ssl] = "true"
end

package "postgresql"

service "postgresql" do
  case node['platform']
  when "ubuntu"
    case
    # PostgreSQL 9.1 on Ubuntu 10.04 gets set up as "postgresql", not "postgresql-9.1"
    # Is this because of the PPA?
    when node['platform_version'].to_f <= 10.04 && node['postgresql']['version'].to_f < 9.0
      service_name "postgresql-#{node['postgresql']['version']}"
    else
      service_name "postgresql"
    end
  when "debian"
    case
    when platform_version.to_f <= 5.0
      service_name "postgresql-#{node['postgresql']['version']}"
    when platform_version =~ /squeeze/
      service_name "postgresql"
    else
      service_name "postgresql"
    end
  end
  supports :restart => true, :status => true, :reload => true
  action :nothing
end

postgresql_conf_source = begin
  if node[:postgresql][:version] == "9.1"
    "debian.postgresql_91.conf.erb"
  else
    "debian.postgresql.conf.erb"
  end
end

template "#{node[:postgresql][:dir]}/postgresql.conf" do
  source postgresql_conf_source
  owner "postgres"
  group "postgres"
  mode 0600
  notifies :restart, resources(:service => "postgresql")
end