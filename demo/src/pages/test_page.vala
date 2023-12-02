using Fabric.UI.Helpers;

namespace FabricDemo.Tenfoot.Pages {
	class Test : Base {
		public static Test instance {
			owned get { return new Test(); }
		}
		private Test() {}

		construct {
			add_css_class("page-test");
			append(make_subheading("Test page"));
			append(make_text(""));
			append(make_text("Hello!"));
		}
	}
}
