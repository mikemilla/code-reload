import React from 'react';
import * as ReactNative from 'react-native';
import {projectStore} from '../store/ProjectStore';
import {transformSource} from './transform';

const builtins: Record<string, any> = {
  react: React,
  'react-native': ReactNative,
};

/// Make additional modules importable from edited code (e.g. an icon library).
/// Call before the app boots so interpreted files can `import` them by name.
export function registerBuiltin(name: string, module: any) {
  builtins[name] = module;
}

let moduleCache: Record<string, any> = {};

export function clearModuleCache() {
  moduleCache = {};
}

function resolvePath(from: string, to: string): string {
  const fromParts = from.split('/');
  fromParts.pop();
  const toParts = to.split('/');

  for (const part of toParts) {
    if (part === '..') {
      fromParts.pop();
    } else if (part !== '.') {
      fromParts.push(part);
    }
  }

  return fromParts.join('/');
}

function resolveFile(path: string): string | undefined {
  if (projectStore.read(path)) return path;

  const extensions = ['.tsx', '.ts', '.jsx', '.js'];
  for (const ext of extensions) {
    if (projectStore.read(path + ext)) return path + ext;
  }

  for (const ext of extensions) {
    const indexPath = path + '/index' + ext;
    if (projectStore.read(indexPath)) return indexPath;
  }

  return undefined;
}

export function requireModule(specifier: string, fromFile: string): any {
  if (builtins[specifier]) {
    return builtins[specifier];
  }

  const isRelative = specifier.startsWith('./') || specifier.startsWith('../');
  if (!isRelative) {
    throw new Error(`Cannot resolve bare specifier "${specifier}". Only bundled modules (react, react-native) and relative imports are supported.`);
  }

  const resolved = resolvePath(fromFile, specifier);
  const filePath = resolveFile(resolved);
  if (!filePath) {
    throw new Error(`Module not found: "${specifier}" (from "${fromFile}")`);
  }

  if (moduleCache[filePath]) {
    return moduleCache[filePath].exports;
  }

  const source = projectStore.read(filePath)!;

  let transformed: string;
  try {
    transformed = transformSource(source, filePath);
  } catch (e: any) {
    throw new Error(`Transform error in ${filePath}: ${e?.message ?? e}`);
  }

  const moduleObj = {exports: {} as any};
  moduleCache[filePath] = moduleObj;

  const requireFn = (spec: string) => requireModule(spec, filePath);

  const dirname = filePath.split('/').slice(0, -1).join('/');

  try {
    const factory = new Function(
      'exports',
      'require',
      'module',
      '__filename',
      '__dirname',
      'React',
      transformed,
    );
    factory(moduleObj.exports, requireFn, moduleObj, filePath, dirname, React);
  } catch (e: any) {
    // Drop the half-initialized module so a fixed version re-evaluates cleanly.
    delete moduleCache[filePath];
    throw new Error(`Error evaluating ${filePath}: ${e?.message ?? e}`);
  }

  return moduleObj.exports;
}

export function evaluateEntry(entryPath: string): React.ComponentType<any> {
  clearModuleCache();
  const mod = requireModule('./' + entryPath, '');
  return mod.default || mod;
}
