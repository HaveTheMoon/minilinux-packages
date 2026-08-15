import fs from 'node:fs'
import path from 'node:path'

const [repositoryDir] = process.argv.slice(2)
if (!repositoryDir) {
  console.error('usage: node prune-unreferenced-archives.mjs REPOSITORY_DIR')
  process.exit(2)
}

const indexPath = path.join(repositoryDir, 'index.json')
const index = JSON.parse(fs.readFileSync(indexPath, 'utf8'))
if (index.format !== 1 || !Array.isArray(index.packages)) {
  throw new Error('unsupported package index format')
}

const referenced = new Set()
for (const pkg of index.packages) {
  if (!pkg.file || path.basename(pkg.file) !== pkg.file || !pkg.file.endsWith('.mlpkg')) {
    throw new Error(`unsafe package file in index: ${pkg.file}`)
  }
  referenced.add(pkg.file)
}

let removed = 0
for (const entry of fs.readdirSync(repositoryDir, { withFileTypes: true })) {
  if (!entry.isFile() || !entry.name.endsWith('.mlpkg') || referenced.has(entry.name)) continue
  fs.unlinkSync(path.join(repositoryDir, entry.name))
  removed += 1
}
console.log(`Removed ${removed} unreferenced archive(s).`)
