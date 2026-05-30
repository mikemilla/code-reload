import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tool_registry.dart';

class GitHubTool extends BunbuTool {
  GitHubTool({required this.token, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final String token;
  final http.Client _http;

  static const _apiBase = 'https://api.github.com';

  @override
  String get name => 'github';

  @override
  String get description =>
      'Interact with GitHub: create branches, commit files, and create pull requests.';

  @override
  List<ToolParameter> get parameters => [
        const ToolParameter(
          name: 'action',
          type: 'string',
          description: 'The GitHub action to perform',
          enumValues: ['create_branch', 'commit_file', 'create_pr', 'list_repos'],
        ),
        const ToolParameter(
          name: 'owner',
          type: 'string',
          description: 'Repository owner (username or org)',
          required_: false,
        ),
        const ToolParameter(
          name: 'repo',
          type: 'string',
          description: 'Repository name',
          required_: false,
        ),
        const ToolParameter(
          name: 'branch',
          type: 'string',
          description: 'Branch name (for create_branch or commit_file)',
          required_: false,
        ),
        const ToolParameter(
          name: 'base_branch',
          type: 'string',
          description: 'Base branch to branch from or merge into',
          required_: false,
        ),
        const ToolParameter(
          name: 'path',
          type: 'string',
          description: 'File path for commit_file',
          required_: false,
        ),
        const ToolParameter(
          name: 'content',
          type: 'string',
          description: 'File content for commit_file',
          required_: false,
        ),
        const ToolParameter(
          name: 'message',
          type: 'string',
          description: 'Commit message or PR title',
          required_: false,
        ),
        const ToolParameter(
          name: 'body',
          type: 'string',
          description: 'PR body/description',
          required_: false,
        ),
      ];

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;
    switch (action) {
      case 'list_repos':
        return _listRepos();
      case 'create_branch':
        return _createBranch(
          owner: args['owner'] as String,
          repo: args['repo'] as String,
          branch: args['branch'] as String,
          baseBranch: args['base_branch'] as String? ?? 'main',
        );
      case 'commit_file':
        return _commitFile(
          owner: args['owner'] as String,
          repo: args['repo'] as String,
          branch: args['branch'] as String,
          path: args['path'] as String,
          content: args['content'] as String,
          message: args['message'] as String? ?? 'Update via Bunbu',
        );
      case 'create_pr':
        return _createPr(
          owner: args['owner'] as String,
          repo: args['repo'] as String,
          branch: args['branch'] as String,
          baseBranch: args['base_branch'] as String? ?? 'main',
          title: args['message'] as String,
          body: args['body'] as String? ?? '',
        );
      default:
        return 'Unknown action: $action';
    }
  }

  Future<String> _listRepos() async {
    final response = await _http.get(
      Uri.parse('$_apiBase/user/repos?sort=updated&per_page=10'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      return 'Error listing repos: ${response.statusCode}';
    }
    final repos = jsonDecode(response.body) as List;
    final names = repos.map((r) => '${r['full_name']}').join('\n');
    return 'Your recent repositories:\n$names';
  }

  Future<String> _createBranch({
    required String owner,
    required String repo,
    required String branch,
    required String baseBranch,
  }) async {
    final refResponse = await _http.get(
      Uri.parse('$_apiBase/repos/$owner/$repo/git/ref/heads/$baseBranch'),
      headers: _headers,
    );
    if (refResponse.statusCode != 200) {
      return 'Error getting base branch: ${refResponse.statusCode}';
    }
    final sha =
        (jsonDecode(refResponse.body) as Map)['object']['sha'] as String;

    final createResponse = await _http.post(
      Uri.parse('$_apiBase/repos/$owner/$repo/git/refs'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'ref': 'refs/heads/$branch', 'sha': sha}),
    );
    if (createResponse.statusCode == 201) {
      return 'Created branch "$branch" from "$baseBranch"';
    }
    return 'Error creating branch: ${createResponse.statusCode} ${createResponse.body}';
  }

  Future<String> _commitFile({
    required String owner,
    required String repo,
    required String branch,
    required String path,
    required String content,
    required String message,
  }) async {
    final existing = await _http.get(
      Uri.parse(
          '$_apiBase/repos/$owner/$repo/contents/$path?ref=$branch'),
      headers: _headers,
    );
    final body = <String, dynamic>{
      'message': message,
      'content': base64Encode(utf8.encode(content)),
      'branch': branch,
    };
    if (existing.statusCode == 200) {
      body['sha'] = (jsonDecode(existing.body) as Map)['sha'];
    }

    final response = await _http.put(
      Uri.parse('$_apiBase/repos/$owner/$repo/contents/$path'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return 'Committed "$path" to branch "$branch"';
    }
    return 'Error committing file: ${response.statusCode} ${response.body}';
  }

  Future<String> _createPr({
    required String owner,
    required String repo,
    required String branch,
    required String baseBranch,
    required String title,
    required String body,
  }) async {
    final response = await _http.post(
      Uri.parse('$_apiBase/repos/$owner/$repo/pulls'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'head': branch,
        'base': baseBranch,
        'body': body,
      }),
    );
    if (response.statusCode == 201) {
      final pr = jsonDecode(response.body) as Map;
      return 'Created PR #${pr['number']}: ${pr['html_url']}';
    }
    return 'Error creating PR: ${response.statusCode} ${response.body}';
  }

  void dispose() {
    _http.close();
  }
}
