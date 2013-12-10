#
# Cookbook Name:: oh_my_zsh
# Recipe:: default
#

if node['oh_my_zsh']['users'].any?
  package "zsh"
  include_recipe "git"
end

# for each listed user
node['oh_my_zsh']['users'].each do |user_hash|
  home_directory = `cat /etc/passwd | grep "#{user_hash[:login]}" | cut -d ":" -f6`.chop

  git "#{home_directory}/.oh-my-zsh" do
    repository 'git://github.com/robbyrussell/oh-my-zsh.git'
    user user_hash[:login]
    reference "master"
    action :sync
  end

  theme_info = user_hash[:theme] || {}
  if theme_info.is_a?(String)
     theme_info = { :name => theme_info, :source => nil }
  end
  if not theme_info[:source].nil? and theme_info != ""
    remote_file "#{home_directory}/.oh-my-zsh/themes/#{theme_info[:name]}.zsh-theme" do
      source theme_info[:source]
      owner user_hash[:login]
      group user_hash[:login]
    end
  end

  template "#{home_directory}/.zshrc" do
    source "zshrc.erb"
    owner user_hash[:login]
    mode "644"
    action :create_if_missing
    variables({
      :user => user_hash[:login],
      :theme => theme_info[:name] || 'robbyrussell',
      :case_sensitive => user_hash[:case_sensitive] || false,
      :plugins => user_hash[:plugins] || %w(git)
    })
  end

  user user_hash[:login] do
    action :modify
    shell '/bin/zsh'
  end


  execute "source /etc/profile to all zshrc" do
    command "echo 'source /etc/profile' >> /etc/zsh/zprofile"
    not_if "grep 'source /etc/profile' /etc/zsh/zprofile"
  end

end
