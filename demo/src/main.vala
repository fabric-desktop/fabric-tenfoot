using Fabric.Tenfoot;

// Make it so we're not a sub-namespace, and thus more privileged in scope.
namespace FabricDemo.Tenfoot {
	class Application : Fabric.Tenfoot.Application {
		construct {
			application_id = "demo.fabric.tenfoot";
		}

		protected override void activate() {
			base.activate();

			var container = Fabric.UI.PagesContainer.instance;
			container.push(Pages.Welcome.instance);

			GlobalMenu.instance.add_item("open-test-page", "Open test page").activate.connect(() => {
				GlobalMenu.instance.hide();
				container.push(Pages.Test.instance);
			});
			GlobalMenu.instance.add_item("quit", "Quit").activate.connect(() => {
				Process.exit(0);
			});

			window = new Fabric.UI.PagedWindow() {
				title = "Fabric Tenfoot — Demo",
				application = this,
			};
			window.present();
		}
	}

	public static int main(string[] args) {
		return (new Application()).run(args);
	}
}
