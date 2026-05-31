/// Default GitHub OAuth app (Build Context / Bunbu) for on-device sign-in.
/// Public by design — device flow does not use a client secret.
/// Host apps may override via `registerBunbuApp({ githubClientId })`.
export const BUNBU_GITHUB_CLIENT_ID = 'Ov23liEN4tusdArQ0uu6';

export function resolveGitHubClientId(override?: string): string {
  return override?.trim() || BUNBU_GITHUB_CLIENT_ID;
}
