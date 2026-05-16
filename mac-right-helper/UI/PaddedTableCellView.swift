import Cocoa

class PaddedTableCellView: NSTableCellView {
    private let hPadding: CGFloat = 8
    private let vPadding: CGFloat = 4

    func configure(with text: String) {
        if let existing = textField {
            existing.stringValue = text
        } else {
            let tf = NSTextField(labelWithString: text)
            tf.translatesAutoresizingMaskIntoConstraints = false
            addSubview(tf)
            NSLayoutConstraint.activate([
                tf.leadingAnchor.constraint(equalTo: leadingAnchor, constant: hPadding),
                tf.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -hPadding),
                tf.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            textField = tf
        }
    }

    func configureCheckbox(state: NSControl.StateValue, tag: Int, target: Any, action: Selector) {
        subviews.filter { $0 is NSButton }.forEach { $0.removeFromSuperview() }
        let cb = NSButton(checkboxWithTitle: "", target: target, action: action)
        cb.state = state
        cb.tag = tag
        cb.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cb)
        NSLayoutConstraint.activate([
            cb.centerXAnchor.constraint(equalTo: centerXAnchor),
            cb.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
