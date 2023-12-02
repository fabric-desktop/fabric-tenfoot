using Fabric.Tenfoot;
using Fabric.UI.Helpers;

namespace FabricDemo.Tenfoot.Pages {
	class Welcome : Base {
		private static GLib.Once<Welcome> _instance;
		public static unowned Welcome instance {
			get { return _instance.once(() => { return new Welcome(); }); }
		}
		private Welcome() {}

		construct {
			add_css_class("page-welcome");

			append(make_subheading("Welcome to the Fabric Tenfoot Demo!"));
			append(make_text(""));
			append(make_text("Don't be alarmed, this application is barely useful."));
			append(make_text(""));
			append(make_text("You'll likely want to use the global menu, or one of the following actions next."));
			append(make_text(""));


			// By virtue of being the first and only button, it cheaply makes
			// it the default action for the global actions.
			// It's better than overriding actions, as the focus on the button
			// shows what is going to happen.
			var button = new Button() {
				halign = Gtk.Align.START,
			};
			button.label = "Continue to the widgets playground";
			button.clicked.connect(() => {
				var container = Fabric.UI.PagesContainer.instance;
				container.push(new Pages.WidgetsPlayground());
			});
			append(button);


			// We're making this the "root" first of the app, and instead of disabling
			// the back action, which would be the default, we'll instead show the menu.
			var back = contextual_action_for("gamepad.back");
			back.activate.disconnect(this.go_back);
			back.activate.connect(() => {
				GlobalMenu.activate_menu_action("_show");
			});
		}
	}
}
