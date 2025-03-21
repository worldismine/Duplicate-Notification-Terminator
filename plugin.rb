# name: discourse-duplicate-notification-terminator
# version: 3.4
# authors: Communiteq and Muhlis Cahyono
# url: https://github.com/worldismine/Duplicate-Notification-Terminator

enabled_site_setting :duplicate_notification_terminator_enabled

%i(common desktop mobile).each do |type|
  register_asset "stylesheets/duplicate-notification-terminator/#{type}.scss", type
end

after_initialize do
  require_dependency "topics_controller"
  class ::TopicsController
    before_action :ensure_can_wipe_notifications, only: [:wipe_admin_notifications]
    after_action :read_all_notifications, only: [:show]

    def read_all_notifications
      if @topic_view&.topic&.id && SiteSetting.duplicate_notification_terminator_enabled && Group.find_by_name(SiteSetting.duplicate_notification_group)&.users&.include?(current_user)
        n_ids = Notification
          .where(user_id: current_user.id, topic_id: @topic_view.topic.id, read: false)
          .pluck(:id)

        if n_ids.present?
          Notification
            .where(id: n_ids)
            .update_all(read: true)

          MessageBus.publish("/duplicate-notification-terminator", n_ids, user_ids: [current_user.id])
          current_user.publish_notifications_state
        end
      end
    end

    def wipe_admin_notifications
      if !SiteSetting.duplicate_notification_admin_btn_enabled
        raise Discourse::InvalidAccess.new
      end

      topic = Topic.find(params[:id])

      users = Group.find_by_name(SiteSetting.duplicate_notification_group)&.users || []
      user_ids = users.map(&:id).uniq

      n_ids = Notification
        .where(user_id: user_ids, topic_id: topic.id, read: false)
        .pluck(:id)

      if n_ids.present?
        Notification
          .where(id: n_ids)
          .update_all(read: true)

        MessageBus.publish("/duplicate-notification-terminator", n_ids, user_ids: user_ids)

        users.each { |u| u.publish_notifications_state }
      end

      render json: success_json
    end

    def ensure_can_wipe_notifications
      raise Discourse::InvalidAccess.new unless current_user && current_user.can_wipe_notifications
    end
  end

  require_dependency "user"
  class ::User
    def can_wipe_notifications
      return false unless SiteSetting.duplicate_notification_terminator_enabled
      Group.find_by_name(SiteSetting.duplicate_notification_group)&.users&.include?(self)
    end
  end

  add_to_serializer(:current_user, :can_wipe_notifications) {
    object.can_wipe_notifications
  }

  Discourse::Application.routes.append {
    post "t/:id/wipe-admin-notifications" => "topics#wipe_admin_notifications"
  }

  register_svg_icon("bell-slash")
end
