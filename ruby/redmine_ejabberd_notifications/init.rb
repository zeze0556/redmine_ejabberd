require "redmine"

require_dependency "notifier_hook"
require_dependency "my_account_hooks"
require_dependency "user_hooks"
require_dependency "user"

if User.const_defined? "SAFE_ATTRIBUTES"
    User::SAFE_ATTRIBUTES << "xmpp_jid"
else
    User.safe_attributes "xmpp_jid"
end

Redmine::Plugin.register :redmine_ejabberd_notifications do
  name "Redmine XMPP(ejabberd) Notifications plugin"
  author "Pavel Musolin & Vadim Misbakh-Soloviov & Yokujin Yokosuka & zeze0556 & Others"
  description "A plugin to send Redmine Activity and receive commands over XMPP"
  version "2.1.0"
  url "https://github.com/redmine-xmpp/notifications"

  settings :default => {"url" => "", "send_to_watchers" => true}, :partial => "settings/xmpp_settings"
end

Rails.logger.info "#{'*'*65}\n* XMPP Bot init.rb\n#{'*'*65}"
