# name: duplicate-notification-terminator
# version: 0.3.2
# author: Muhlis Cahyono (muhlisbc@gmail.com)
# url: https://github.com/worldismine/Duplicate-Notification-Terminator

enabled_site_setting :duplicate_notification_terminator_enabled

%i(common desktop mobile).each do |type|
  register_asset "stylesheets/duplicate-notification-terminator/#{type}.scss", type
end

after_initialize do
  require_dependency "topics_controller"
  class ::TopicsController
    before_action :ensure_admin, only: [:wipe_admin_notifications]
    after_action :read_all_notifications, only: [:show]

    def read_all_notifications
      if @topic_view&.topic&.id && current_user&.staff? && SiteSetting.duplicate_notification_terminator_enabled
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

      admins = User.where(admin: true)
      admin_ids = admins.map(&:id)

      n_ids = Notification
        .where(user_id: admin_ids, topic_id: topic.id, read: false)
        .pluck(:id)

      if n_ids.present?
        Notification
          .where(id: n_ids)
          .update_all(read: true)

        MessageBus.publish("/duplicate-notification-terminator", n_ids, user_ids: admin_ids)

        admins.each { |adm| adm.publish_notifications_state }
      end

      render json: success_json
    end
  end

  Discourse::Application.routes.append {
    post "t/:id/wipe-admin-notifications" => "topics#wipe_admin_notifications"
  }

  register_svg_icon("bell-slash")
end
