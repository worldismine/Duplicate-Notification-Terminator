import { withPluginApi } from 'discourse/lib/plugin-api';
import NotificationsRoute from "discourse/routes/user-notifications";

function initWithApi(api) {
  const messageBus  = api.container.lookup("message-bus:main");
  const appEvents   = api.container.lookup("app-events:main");
  const eventName   = "duplicate-notification-terminator";

  let widgetSubbed;

  messageBus.subscribe("/duplicate-notification-terminator", (nIds) => {
    appEvents.trigger(eventName, nIds);
  });

  NotificationsRoute.reopen({
    setupController(controller, model) {
      this.appEvents.on(eventName, (nIds) => {
        controller.get("model").filter((x) => nIds.includes(x.id)).setEach("read", true);
      });

      this._super(...arguments);
    },

    actions: {
      willTransition() {
        this.appEvents.off(eventName);
        this._super(...arguments);
      }
    }
  });

  api.reopenWidget("user-notifications", {
    html(attrs, state) {
      if (!widgetSubbed) {
        this.appEvents.on(eventName, (nIds) => {
          this.refreshNotifications(state);
        });

        widgetSubbed = true;
      }

      return this._super(...arguments);
    }
  });
}

export default {
  name: "duplicate-notification-terminator",

  initialize() {
    withPluginApi("0.8", initWithApi);
  }
};
