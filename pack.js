const { execSync } = require('child_process');
const { writeFileSync, mkdirSync, existsSync } = require('fs');
const path = require('path');

const packagesInWorkSpace = execSync('pnpm ls --depth -1 -r --json');

const rootDir = path.resolve(__dirname, '.');
const appPackageJson = require(path.resolve(rootDir, 'package.json'));
const list = JSON.parse(String(packagesInWorkSpace)).filter((pkg) => pkg.name !== appPackageJson.name);

const buildedPackageJson = {
  name: appPackageJson.name,
  private: true,
  description: appPackageJson.description,
  dependencies: appPackageJson.dependencies,
};

const distFolder = path.resolve(rootDir, 'dist');
if (!existsSync(distFolder)) {
  mkdirSync(distFolder, { recursive: true });
}

function addPackageRecursive(package) {
  if (package) {
    if (package.name !== appPackageJson.name) {
      const tarName = path.basename(
        String(execSync(`pnpm -F ${package.name} exec pnpm pack --pack-destination ${distFolder}`)).trim()
      );

      buildedPackageJson.dependencies[package.name] = `file:./${tarName}`;
    }
  }

  const packageJson = package ? require(path.join(package.path, 'package.json')) : appPackageJson;

  Object.keys(packageJson.dependencies || {}).forEach((dependencyName) => {
    const package = list.find((list) => list.name === dependencyName);
    if (package) {
      addPackageRecursive(package);
    }
  });
}

addPackageRecursive();

writeFileSync(path.resolve(distFolder, 'package.json'), JSON.stringify(buildedPackageJson, null, 4));
