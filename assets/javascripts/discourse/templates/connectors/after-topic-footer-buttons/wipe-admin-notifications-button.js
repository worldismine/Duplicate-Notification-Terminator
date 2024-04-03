import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default {
  actions: {
    wipeNotifications(topicId) {
      if (this.get("loading")) return;

      this.set("loading", true);

      ajax(`/t/${topicId}/wipe-admin-notifications`, { type: "POST" })
        .catch(popupAjaxError)
        .finally(() => this.set("loading", false));
    }
  }
}
