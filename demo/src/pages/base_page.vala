using Fabric.Tenfoot;

namespace FabricDemo.Tenfoot.Pages {
	// Move to Fabric.Tenfoot.BasePage
	class Base : Fabric.UI.ScrollingPage, ContextualWidget {
		construct {
			// Hook the back action to the intrinsic `go_back` action.
			contextual_action_add("gamepad.back", "Back")
				.activate.connect(this.go_back)
			;
		}

		public override bool grab_focus() {
			scroll_to_top();

			return true;
		}
	}
}
