package cjreleaser

import std.collection.*

public class DepGraph {
    var reverseEdges: HashMap<String, ArrayList<String>> = HashMap<String, ArrayList<String>>()
    var allNodes: HashSet<String> = HashSet<String>()
    var packages: HashMap<String, PackageInfo>

    public init(packages: HashMap<String, PackageInfo>) {
        this.packages = packages
    }

    public func build(): Bool {
        for ((name, pkg) in packages) {
            allNodes.add(name)
            for ((depName, depInfo) in pkg.dependencies) {
                if (depInfo.isPathDep() && packages.contains(depName)) {
                    if (!reverseEdges.contains(depName)) {
                        reverseEdges.add(depName, ArrayList<String>())
                    }
                    if (let Some(list) <- reverseEdges.get(depName)) {
                        list.add(name)
                    }
                }
            }
        }
        return true
    }

    public func topologicalSort(): ?Array<String> {
        let inDegree: HashMap<String, Int64> = HashMap<String, Int64>()
        for (node in allNodes) {
            inDegree.add(node, 0)
        }

        for ((dep, dependents) in reverseEdges) {
            for (dependent in dependents) {
                if (let Some(d) <- inDegree.get(dependent)) {
                    inDegree.add(dependent, d + 1)
                }
            }
        }

        let queue = ArrayList<String>()
        for ((node, degree) in inDegree) {
            if (degree == 0) {
                queue.add(node)
            }
        }

        let result = ArrayList<String>()
        var idx = 0
        while (idx < queue.size) {
            let node = queue[idx]
            result.add(node)
            idx = idx + 1

            if (let Some(dependents) <- reverseEdges.get(node)) {
                for (dependent in dependents) {
                    if (let Some(d) <- inDegree.get(dependent)) {
                        inDegree.add(dependent, d - 1)
                    }
                }
            }

            for ((n, degree) in inDegree) {
                if (degree == 0 && !result.contains(n) && !queue.contains(n)) {
                    queue.add(n)
                }
            }
        }

        if (result.size != allNodes.size) {
            eprintln("Error: circular dependency detected among packages")
            return None
        }

        return result.toArray()
    }
}
