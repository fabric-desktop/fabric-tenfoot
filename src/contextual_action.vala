namespace Fabric.Tenfoot {
	public class ContextualActionGroup : HashTable<string, ContextualAction> {
		public ContextualActionGroup() {
			base(str_hash, str_equal);
		}
	}

	/**
	 * Implements a similar interface to Action, but with a contextual `label`.
	 * Note that ContextualAction takes no parameter, and cannot be used as
	 * stateful actions.
	 *
	 * > It is impossible to implement the `Action` interface in Vala.
	 * > I was told it should not be implemented, either.
	 * > ¯\_(ツ)_/¯
	 */
	public class ContextualAction : Object {
		public bool enabled { get; set; }
		public string name { get; private set; }
		public string label { get; set; }

		public signal void activate();

		public ContextualAction(string name, string? label) {
			this.enabled = true;
			this.name = name;
			if (label == null) {
				this.label = "(%s)".printf(name);
			}
			else {
				this.label = label;
			}
		}
	}
}
