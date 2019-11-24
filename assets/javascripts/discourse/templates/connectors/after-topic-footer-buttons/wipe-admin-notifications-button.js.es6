import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default {
  setupComponent({ topic }, component) {
    component.set("topic", topic);
  },

  actions: {
    wipeNotifications() {
      if (this.get("loading")) return;

      this.set("loading", true);

      ajax(`/t/${this.get("topic.id")}/wipe-admin-notifications`, { type: "POST" })
        .catch(popupAjaxError)
        .finally(() => this.set("loading", false));
    }
  }
}
