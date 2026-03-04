import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/components/d-button";

export default class WipeAdminNotificationsButton extends Component {
  @service currentUser;
  @service site;
  @service siteSettings;

  @tracked loading = false;

  // In modern plugin outlets, mapped arguments live inside `@outletArgs`
  get topic() {
    return this.args.outletArgs?.topic ?? this.args.topic;
  }

  get shouldShowButton() {
    return (
      this.topic?.isPrivateMessage &&
      this.currentUser?.can_wipe_notifications &&
      this.siteSettings.duplicate_notification_admin_btn_enabled
    );
  }

  get buttonLabel() {
    return this.site.mobileView
      ? undefined
      : "duplicate_notification_terminator.wipe_notifications";
  }

  @action
  async wipeNotifications() {
    if (this.loading || !this.topic?.id) {
      return;
    }

    this.loading = true;

    try {
      await ajax(`/t/${this.topic.id}/wipe-admin-notifications`, {
        type: "POST",
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  <template>
    {{#if this.shouldShowButton}}
      <span class="wipe-admin-notifications-button">
        <DButton
          class="btn-danger btn-large"
          @action={{this.wipeNotifications}}
          @disabled={{this.loading}}
          @label={{this.buttonLabel}}
          @icon="bell-slash"
        />
      </span>
    {{/if}}
  </template>
}
