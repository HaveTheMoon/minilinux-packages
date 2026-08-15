import fs from 'node:fs'
import path from 'node:path'

const [publishedPath, builtPath, destinationPath, updatesPath, mode = 'outdated'] = process.argv.slice(2)
if (!publishedPath || !builtPath || !destinationPath || !updatesPath || !['outdated', 'rebuild_all'].includes(mode)) {
  console.error('usage: node prepare-package-updates.mjs PUBLISHED.json BUILT.json DESTINATION UPDATES.json [outdated|rebuild_all]')
  process.exit(2)
}

const published = JSON.parse(fs.readFileSync(publishedPath, 'utf8'))
const built = JSON.parse(fs.readFileSync(builtPath, 'utf8'))
if (published.format !== 1 || built.format !== 1 || !Array.isArray(published.packages) || !Array.isArray(built.packages)) {
  throw new Error('unsupported package index format')
}

const current = new Map(published.packages.map((pkg) => [pkg.name, pkg]))
const selected = built.packages.filter((pkg) => mode === 'rebuild_all' || !current.has(pkg.name) || current.get(pkg.name).version !== pkg.version)
fs.mkdirSync(destinationPath, { recursive: true })
for (const pkg of selected) {
  if (path.basename(pkg.file) !== pkg.file || !pkg.file.endsWith('.mlpkg')) throw new Error(`unsafe package file: ${pkg.file}`)
  const sourceArchive = path.join(path.dirname(builtPath), pkg.file)
  if (!fs.existsSync(sourceArchive)) throw new Error(`built archive missing: ${pkg.file}`)
  fs.copyFileSync(sourceArchive, path.join(destinationPath, pkg.file))
}
const lines = selected.map((pkg) => JSON.stringify(pkg)).join(',\n')
fs.writeFileSync(updatesPath, `{"format":1,"packages":[\n${lines}\n]}\n`)
console.log(`Prepared ${selected.length} package update(s) in ${mode} mode.`)
