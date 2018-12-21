import UIKit

final class SuggestionTableView: UITableView {
    private var suggestions: [String] = []

    func reloadSuggestions(_ suggestions: [String]) {
        self.suggestions = suggestions
        heightConstraint.constant = CGFloat(suggestions.count * 44)
        reloadData()
    }

    private var heightConstraint: NSLayoutConstraint!
    private let reuseID = UUID().uuidString
    private let tappedIndexHandler: (Int) -> ()

    init(suggestions: [String], tappedIndexHandler: @escaping (Int) -> ()) {
        self.suggestions = suggestions
        self.tappedIndexHandler = tappedIndexHandler

        super.init(frame: .zero, style: .plain)

        delegate = self
        dataSource = self

        register(UITableViewCell.self, forCellReuseIdentifier: reuseID)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateConstraints() {
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true

        super.updateConstraints()
    }
}

extension SuggestionTableView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        cell.textLabel?.text = suggestions[indexPath.row]
        return cell
    }
}

extension SuggestionTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        tappedIndexHandler(indexPath.row)
    }
}
