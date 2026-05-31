import {transform} from 'sucrase';

export function transformSource(code: string, filePath: string): string {
  const isTS =
    filePath.endsWith('.ts') ||
    filePath.endsWith('.tsx');
  const isJSX =
    filePath.endsWith('.tsx') ||
    filePath.endsWith('.jsx');

  const transforms: Array<'typescript' | 'jsx' | 'imports'> = ['imports'];
  if (isTS) transforms.unshift('typescript');
  if (isJSX) transforms.unshift('jsx');

  const result = transform(code, {
    transforms,
    jsxRuntime: 'classic',
    production: true,
  });

  return result.code;
}
