# name: duplicate-notification-terminator
# version: 0.1.0
# author: Muhlis Cahyono (muhlisbc@gmail.com)
# url: https://github.com/worldismine/Duplicate-Notification-Terminator

enabled_site_setting :duplicate_notification_terminator_enabled

after_initialize do
  require_dependency "topics_controller"
  class ::TopicsController
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
        end
      end
    end
  end
end
