import crypto from 'node:crypto'
import fs from 'node:fs'
import path from 'node:path'

const [repositoryPath] = process.argv.slice(2)
if (!repositoryPath) {
  console.error('usage: node verify-repository-index.mjs X86_64_DIRECTORY')
  process.exit(2)
}

const root = path.resolve(repositoryPath)
const indexPath = path.join(root, 'index.json')
const index = JSON.parse(fs.readFileSync(indexPath, 'utf8'))
if (index.format !== 1 || !Array.isArray(index.packages)) throw new Error('invalid index format')

const names = new Set()
const errors = []
for (const pkg of index.packages) {
  if (!pkg || typeof pkg.name !== 'string' || typeof pkg.file !== 'string' || typeof pkg.sha256 !== 'string') {
    errors.push('invalid package record')
    continue
  }
  if (names.has(pkg.name)) errors.push(`duplicate package name: ${pkg.name}`)
  names.add(pkg.name)
  if (path.basename(pkg.file) !== pkg.file || !pkg.file.endsWith('.mlpkg')) {
    errors.push(`unsafe package file: ${pkg.file}`)
    continue
  }
  const archive = path.join(root, pkg.file)
  if (!fs.existsSync(archive)) {
    errors.push(`missing archive: ${pkg.file}`)
    continue
  }
  const digest = crypto.createHash('sha256').update(fs.readFileSync(archive)).digest('hex')
  if (digest !== pkg.sha256) errors.push(`SHA-256 mismatch: ${pkg.file}`)
}
if (errors.length) throw new Error(errors.join('\n'))
console.log(`Verified ${index.packages.length} package record(s) and SHA-256 archive checksum(s).`)
