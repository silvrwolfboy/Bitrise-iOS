import APIKit
import SwiftyUserDefaults
import UIKit

final class BuildsListViewController: UIViewController, Storyboardable, UITableViewDataSource, UITableViewDelegate {

    struct Dependency {
        let appSlug: String
        let appName: String
        let userDefaults: UserDefaults
        init(appSlug: String,
             appName: String,
             userDefaults: UserDefaults = Config.defaults) {
            self.appSlug = appSlug
            self.appName = appName
            self.userDefaults = userDefaults
        }
    }

    static func makeFromStoryboard(_ dependency: Dependency) -> BuildsListViewController {
        let vc = BuildsListViewController.unsafeMakeFromStoryboard()
        vc.appSlug = dependency.appSlug
        vc.appName = dependency.appName
        vc.userDefaults = dependency.userDefaults
        return vc
    }

    private var appSlug: String!
    private var appName: String!
    private var userDefaults: UserDefaults!
    private var builds: [AppsBuilds.Build] = []

    @IBOutlet private weak var triggerBuildButton: UIButton! {
        didSet {
            triggerBuildButton.layer.cornerRadius = 20
        }
    }

    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }

    // MARK: LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // save app-title
        userDefaults[.lastAppNameVisited] = appName

        navigationItem.title = appName

        fetchDataAndReloadTable()
    }

    // MARK: API Call

    // TODO: Insert Animation
    private func fetchDataAndReloadTable() {
        let req = AppsBuildsRequest(appSlug: appSlug)
        Session.shared.send(req) { [weak self] result in
            guard let me = self else { return }

            switch result {
            case .success(let res):
                me.builds = res.data
                me.tableView.reloadData()
            case .failure(let error):
                print(error)
            }
        }
    }

    private func sendAbortRequest(indexPath: IndexPath) {
        let buildSlug = builds[indexPath.row].slug
        let buildNumber = builds[indexPath.row].build_number
        let req = AppsBuildsAbortRequest(appSlug: appSlug, buildSlug: buildSlug)

        Session.shared.send(req) { [weak self] result in
            guard let me = self else { return }

            switch result {
            case .success(let res):
                if let msg = res.error_msg {
                    me.alert(msg)
                } else {
                    me.alert("Aborted: #\(buildNumber)") { [weak self] _ in
                        self?.fetchDataAndReloadTable()
                    }
                }
            case .failure(let error):
                self?.alert("Abort failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: IBAction

    @IBAction func triggerBuildButtonTap() {
        let vc = TriggerBuildViewController.makeFromStoryboard(TriggerBuildLogicStore(appSlug: appSlug))
        vc.modalPresentationStyle = .overCurrentContext
        navigationController?.present(vc, animated: true, completion: nil)
    }

    // MARK: UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return builds.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BuildCell") as! BuildCell
        cell.configure(builds[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Abort", style: .default, handler: { [weak self] _ in
            self?.sendAbortRequest(indexPath: indexPath)
        }))

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(actionSheet, animated: true, completion: nil)
    }
}
