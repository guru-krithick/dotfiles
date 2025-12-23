-- LuaSnip for competitive programming snippets
return {
	"L3MON4D3/LuaSnip",
	event = "InsertEnter",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	config = function()
		local ls = require("luasnip")
		local s = ls.snippet
		local t = ls.text_node
		local i = ls.insert_node
		local f = ls.function_node
		local c = ls.choice_node

		-- Load friendly-snippets
		require("luasnip.loaders.from_vscode").lazy_load()

		-- Keymaps for snippet navigation
		vim.keymap.set({ "i", "s" }, "<C-l>", function()
			if ls.expand_or_jumpable() then
				ls.expand_or_jump()
			end
		end, { silent = true, desc = "Snippet: Expand or jump" })

		vim.keymap.set({ "i", "s" }, "<C-h>", function()
			if ls.jumpable(-1) then
				ls.jump(-1)
			end
		end, { silent = true, desc = "Snippet: Jump back" })

		vim.keymap.set({ "i", "s" }, "<C-j>", function()
			if ls.choice_active() then
				ls.change_choice(1)
			end
		end, { silent = true, desc = "Snippet: Next choice" })

		-- ══════════════════════════════════════════════════════════════════════
		-- C++ COMPETITIVE PROGRAMMING SNIPPETS
		-- ══════════════════════════════════════════════════════════════════════

		ls.add_snippets("cpp", {
			-- Template
			s("cptemp", {
				t({
					"#include <bits/stdc++.h>",
					"using namespace std;",
					"",
					"using ll = long long;",
					"using vi = vector<int>;",
					"using pii = pair<int, int>;",
					"#define all(x) (x).begin(), (x).end()",
					"#define sz(x) (int)(x).size()",
					"",
					"void solve() {",
					"    ",
				}),
				i(1),
				t({
					"",
					"}",
					"",
					"int main() {",
					"    ios::sync_with_stdio(false);",
					"    cin.tie(nullptr);",
					"    int t = 1;",
					"    // cin >> t;",
					"    while (t--) solve();",
					"    return 0;",
					"}",
				}),
			}),

			-- For loop
			s("fori", {
				t("for (int i = 0; i < "),
				i(1, "n"),
				t("; i++) {"),
				t({ "", "    " }),
				i(2),
				t({ "", "}" }),
			}),

			-- Range-based for loop
			s("forr", {
				t("for (auto& "),
				i(1, "x"),
				t(" : "),
				i(2, "arr"),
				t(") {"),
				t({ "", "    " }),
				i(3),
				t({ "", "}" }),
			}),

			-- Read vector
			s("readvec", {
				t("int "),
				i(1, "n"),
				t("; cin >> "),
				f(function(args)
					return args[1][1]
				end, { 1 }),
				t({ ";", "vector<int> " }),
				i(2, "a"),
				t("("),
				f(function(args)
					return args[1][1]
				end, { 1 }),
				t({ ");", "for (auto& x : " }),
				f(function(args)
					return args[1][1]
				end, { 2 }),
				t(") cin >> x;"),
			}),

			-- Binary search
			s("bins", {
				t({ "int lo = 0, hi = ", "" }),
				i(1, "n"),
				t({ ";", "while (lo < hi) {", "    int mid = lo + (hi - lo) / 2;", "    if (" }),
				i(2, "condition"),
				t({ ") {", "        hi = mid;", "    } else {", "        lo = mid + 1;", "    }", "}" }),
			}),

			-- DFS template
			s("dfs", {
				t({
					"vector<vector<int>> adj;",
					"vector<bool> visited;",
					"",
					"void dfs(int u) {",
					"    visited[u] = true;",
					"    for (int v : adj[u]) {",
					"        if (!visited[v]) {",
					"            dfs(v);",
					"        }",
					"    }",
					"}",
				}),
			}),

			-- BFS template
			s("bfs", {
				t({
					"void bfs(int start) {",
					"    vector<int> dist(n, -1);",
					"    queue<int> q;",
					"    q.push(start);",
					"    dist[start] = 0;",
					"    while (!q.empty()) {",
					"        int u = q.front();",
					"        q.pop();",
					"        for (int v : adj[u]) {",
					"            if (dist[v] == -1) {",
					"                dist[v] = dist[u] + 1;",
					"                q.push(v);",
					"            }",
					"        }",
					"    }",
					"}",
				}),
			}),

			-- Segment tree
			s("segtree", {
				t({
					"struct SegTree {",
					"    int n;",
					"    vector<long long> tree;",
					"    ",
					"    SegTree(int n) : n(n), tree(4 * n) {}",
					"    ",
					"    void build(vector<int>& a, int v, int tl, int tr) {",
					"        if (tl == tr) {",
					"            tree[v] = a[tl];",
					"        } else {",
					"            int tm = (tl + tr) / 2;",
					"            build(a, v*2, tl, tm);",
					"            build(a, v*2+1, tm+1, tr);",
					"            tree[v] = tree[v*2] + tree[v*2+1];",
					"        }",
					"    }",
					"    ",
					"    void update(int v, int tl, int tr, int pos, int val) {",
					"        if (tl == tr) {",
					"            tree[v] = val;",
					"        } else {",
					"            int tm = (tl + tr) / 2;",
					"            if (pos <= tm) update(v*2, tl, tm, pos, val);",
					"            else update(v*2+1, tm+1, tr, pos, val);",
					"            tree[v] = tree[v*2] + tree[v*2+1];",
					"        }",
					"    }",
					"    ",
					"    long long query(int v, int tl, int tr, int l, int r) {",
					"        if (l > r) return 0;",
					"        if (l == tl && r == tr) return tree[v];",
					"        int tm = (tl + tr) / 2;",
					"        return query(v*2, tl, tm, l, min(r, tm))",
					"             + query(v*2+1, tm+1, tr, max(l, tm+1), r);",
					"    }",
					"};",
				}),
			}),

			-- DSU (Union Find)
			s("dsu", {
				t({
					"struct DSU {",
					"    vector<int> p, rank_;",
					"    DSU(int n) : p(n), rank_(n, 0) { iota(p.begin(), p.end(), 0); }",
					"    int find(int x) { return p[x] == x ? x : p[x] = find(p[x]); }",
					"    bool unite(int x, int y) {",
					"        x = find(x); y = find(y);",
					"        if (x == y) return false;",
					"        if (rank_[x] < rank_[y]) swap(x, y);",
					"        p[y] = x;",
					"        if (rank_[x] == rank_[y]) rank_[x]++;",
					"        return true;",
					"    }",
					"};",
				}),
			}),

			-- Modular arithmetic
			s("modint", {
				t({
					"const int MOD = 1e9 + 7;",
					"long long mod(long long x) { return ((x % MOD) + MOD) % MOD; }",
					"long long add(long long a, long long b) { return mod(a + b); }",
					"long long sub(long long a, long long b) { return mod(a - b); }",
					"long long mul(long long a, long long b) { return mod(a * b); }",
					"long long power(long long a, long loSun TV
ng b) {",
					"    long long res = 1;",
					"    a = mod(a);",
					"    while (b > 0) {",
					"        if (b & 1) res = mul(res, a);",
					"        a = mul(a, a);",
					"        b >>= 1;",
					"    }",
					"    return res;",
					"}",
					"long long inv(long long a) { return power(a, MOD - 2); }",
					"long long divide(long long a, long long b) { return mul(a, inv(b)); }",
				}),
			}),

			-- Dijkstra
			s("dijkstra", {
				t({
					"vector<long long> dijkstra(int src, vector<vector<pair<int, int>>>& adj) {",
					"    int n = adj.size();",
					"    vector<long long> dist(n, LLONG_MAX);",
					"    priority_queue<pair<long long, int>, vector<pair<long long, int>>, greater<>> pq;",
					"    dist[src] = 0;",
					"    pq.push({0, src});",
					"    while (!pq.empty()) {",
					"        auto [d, u] = pq.top();",
					"        pq.pop();",Sun TV

					"        if (d > dist[u]) continue;",
					"        for (auto [v, w] : adj[u]) {",
					"            if (dist[u] + w < dist[v]) {",
					"                dist[v] = dist[u] + w;",
					"                pq.push({dist[v], v});",
					"            }",
					"        }",
					"    }",
					"    return dist;",
					"}",
				}),
			}),

			-- Prime sieve
			s("sieve", {
				t({
					"vector<int> sieve(int n) {",
					"    vector<bool> is_prime(n + 1, true);",
					"    vector<int> primes;",
					"    is_prime[0] = is_prime[1] = false;",
					"    for (int i = 2; i <= n; i++) {",
					"        if (is_prime[i]) {",
					"            primes.push_back(i);",
					"            for (long long j = (long long)i * i; j <= n; j += i) {",
					"                is_prime[j] = false;",
					"            }",
					"        }",
					"    }",
					"    return primes;",
					"}",
				}),
			}),

			-- Fenwick Tree (BIT)
			s("fenwick", {
				t({
					"struct Fenwick {",
					"    int n;",
					"    vector<long long> tree;",
					"    Fenwick(int n) : n(n), tree(n + 1, 0) {}",
					"    void update(int i, long long delta) {",
					"        for (++i; i <= n; i += i & (-i)) tree[i] += delta;",
					"    }",
					"    long long query(int i) {",
					"        long long sum = 0;",
					"        for (++i; i > 0; i -= i & (-i)) sum += tree[i];",
					"        return sum;",
					"    }",
					"    long long query(int l, int r) { return query(r) - (l ? query(l - 1) : 0); }",
					"};",
				}),
			}),

			-- LCA with binary lifting
			s("lca", {
				t({
					"const int LOG = 20;",
					"vector<vector<int>> adj;",
					"int up[N][LOG], depth[N];",
					"",
					"void dfs(int u, int p) {",
					"    up[u][0] = p;",
					"    for (int i = 1; i < LOG; i++)",
					"        up[u][i] = up[up[u][i-1]][i-1];",
					"    for (int v : adj[u]) {",
					"        if (v != p) {",
					"            depth[v] = depth[u] + 1;",
					"            dfs(v, u);",
					"        }",
					"    }",
					"}",
					"",
					"int lca(int a, int b) {",
					"    if (depth[a] < depth[b]) swap(a, b);",
					"    int diff = depth[a] - depth[b];",
					"    for (int i = 0; i < LOG; i++)",
					"        if ((diff >> i) & 1) a = up[a][i];",
					"    if (a == b) return a;",
					"    for (int i = LOG - 1; i >= 0; i--)",
					"        if (up[a][i] != up[b][i]) { a = up[a][i]; b = up[b][i]; }",
					"    return up[a][0];",
					"}",
				}),
			}),

			-- Read graph
			s("readgraph", {
				t("int n, m; cin >> n >> m;"),
				t({ "", "vector<vector<int>> adj(n);" }),
				t({ "", "for (int i = 0; i < m; i++) {" }),
				t({ "", "    int u, v; cin >> u >> v;" }),
				t({ "", "    u--; v--;  // 0-indexed" }),
				t({ "", "    adj[u].push_back(v);" }),
				t({ "", "    adj[v].push_back(u);  // remove for directed" }),
				t({ "", "}" }),
			}),

			-- 2D prefix sum
			s("prefix2d", {
				t({
					"// Build 2D prefix sum",
					"vector<vector<long long>> prefix(n + 1, vector<long long>(m + 1, 0));",
					"for (int i = 1; i <= n; i++) {",
					"    for (int j = 1; j <= m; j++) {",
					"        prefix[i][j] = a[i-1][j-1] + prefix[i-1][j] + prefix[i][j-1] - prefix[i-1][j-1];",
					"    }",
					"}",
					"// Query sum in rectangle (r1, c1) to (r2, c2) (0-indexed, inclusive)",
					"// sum = prefix[r2+1][c2+1] - prefix[r1][c2+1] - prefix[r2+1][c1] + prefix[r1][c1];",
				}),
			}),
		})
	end,
}
